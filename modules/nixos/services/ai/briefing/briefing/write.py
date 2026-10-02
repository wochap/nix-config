"""Stage write: turn ranked stories and facts into a chaptered spoken script.

usage: briefing-write --profile profile.json --mode daily|weekly --date YYYY-MM-DD
                      --stories enriched.jsonl --facts facts.json --out DIR

Writes DIR/chapters.json ([{key, title, text}]), DIR/script.md and
DIR/stories.jsonl (input stories annotated with `used` and `chapter`).
One LLM call per chapter (in parallel) keeps every request small, then one
call writes the intro and outro from the finished chapters.
"""

import argparse
import json
import os
from concurrent.futures import ThreadPoolExecutor

from briefing.common import llm, llm_json, log, read_json, read_jsonl, read_text, write_json, write_jsonl

STAGE = "write"


def render(template, values):
    for key, value in values.items():
        template = template.replace("{{" + key + "}}", str(value))
    return template


def highlights_for(chapter, facts):
    """Chapter `facts` entries are "source" or "source:tag"."""
    lines = []
    for spec in chapter.get("facts", []):
        source, _, tag = spec.partition(":")
        for fact_set in facts:
            if fact_set.get("source") != source:
                continue
            for highlight in fact_set.get("highlights", []):
                text, htag = (highlight, "") if isinstance(highlight, str) else (highlight.get("text", ""), highlight.get("tag", ""))
                if not tag or htag == tag:
                    lines.append(f"- {text}")
    return lines


def story_block(story, index, body_chars):
    feeds = ", ".join(sorted({s["feed"] for s in story.get("sources", []) if s.get("feed")}))
    lines = [f"[{index}] {story['title']}", f"Sources: {feeds}", f"Published: {story.get('published', '')}"]
    if story.get("hype"):
        lines.append("Editor flag: possible hype.")
    if story.get("reason"):
        lines.append(f"Why picked: {story['reason']}")
    if story.get("body"):
        lines.append(f"Article text: {story['body'][:body_chars]}")
    else:
        for source in story.get("sources", [])[:3]:
            if source.get("snippet"):
                lines.append(f"{source['feed']}: {source['snippet']}")
    return "\n".join(lines)


def assign(stories, chapters):
    """Hype-flagged stories go to the hype chapter when it exists, else to their topic."""
    keys = {c["key"] for c in chapters}
    hype_key = next((c["key"] for c in chapters if c.get("kind") == "hype"), None)
    buckets = {c["key"]: [] for c in chapters}
    for story in stories:
        key = hype_key if story.get("hype") and hype_key else story.get("topic")
        if key in keys:
            buckets[key].append(story)
    return buckets


def write_chapter(chapter, stories, fact_lines, words, base, prompt):
    if not stories and not fact_lines:
        return None
    system = render(prompt, {**base, "title": chapter["title"], "description": chapter["description"], "words": words})
    parts = []
    if fact_lines:
        parts.append("FACTS (computed, authoritative):\n" + "\n".join(fact_lines))
    if stories:
        parts.append("STORIES (most important first):\n\n" + "\n\n".join(story_block(s, i + 1, 2500 if i < 4 else 1000) for i, s in enumerate(stories)))
    text = llm([{"role": "system", "content": system}, {"role": "user", "content": "\n\n".join(parts)}], temperature=0.5, stage=STAGE)
    if text.strip().upper().startswith("SKIP"):
        log(STAGE, f"{chapter['key']}: model skipped")
        return None
    return {"key": chapter["key"], "title": chapter["title"], "text": text.strip()}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--mode", default="daily")
    parser.add_argument("--date", required=True)
    parser.add_argument("--stories", required=True)
    parser.add_argument("--facts", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--prompts", default=os.environ.get("BRIEFING_PROMPTS", ""))
    args = parser.parse_args()

    profile = read_json(args.profile)
    settings = profile[args.mode]
    stories = read_jsonl(args.stories)
    facts = read_json(args.facts, [])
    chapters = profile["chapters"]
    buckets = assign(stories, chapters)
    fact_lines = {c["key"]: highlights_for(c, facts) for c in chapters}

    base = {"show": profile["show"], "mode": args.mode, "date": args.date, "interests": profile["interests"]}
    body_words = int(settings["words"]) - int(settings["introWords"]) - int(settings["outroWords"])
    weights = {c["key"]: len(buckets[c["key"]]) + (2 if fact_lines[c["key"]] else 0) for c in chapters}
    total = sum(weights.values()) or 1
    chapter_prompt = read_text(os.path.join(args.prompts, "chapter.md"))

    def job(chapter):
        words = max(120, round(body_words * weights[chapter["key"]] / total))
        return write_chapter(chapter, buckets[chapter["key"]], fact_lines[chapter["key"]], words, base, chapter_prompt)

    with ThreadPoolExecutor(max_workers=3) as pool:
        written = [c for c in pool.map(job, chapters) if c]
    if not written:
        raise SystemExit("write: no chapter had content")

    framing = llm_json(
        [
            {"role": "system", "content": render(read_text(os.path.join(args.prompts, "intro.md")), {**base, "introWords": settings["introWords"], "outroWords": settings["outroWords"]})},
            {"role": "user", "content": "\n\n".join(f"CHAPTER: {c['title']}\n{c['text']}" for c in written)},
        ],
        temperature=0.5,
        stage=STAGE,
    )
    all_chapters = (
        [{"key": "intro", "title": "Intro", "text": framing["intro"].strip()}]
        + written
        + [{"key": "outro", "title": "Wrap-up", "text": framing["outro"].strip()}]
    )

    used_keys = {c["key"] for c in written}
    for key, members in buckets.items():
        for story in members:
            story["chapter"] = key
            story["used"] = key in used_keys

    os.makedirs(args.out, exist_ok=True)
    write_json(os.path.join(args.out, "chapters.json"), all_chapters)
    write_jsonl(os.path.join(args.out, "stories.jsonl"), stories)
    with open(os.path.join(args.out, "script.md"), "w", encoding="utf-8") as handle:
        handle.write(f"# {profile['show']}: {args.mode} briefing, {args.date}\n\n")
        for chapter in all_chapters:
            handle.write(f"## {chapter['title']}\n\n{chapter['text']}\n\n")
            for story in buckets.get(chapter["key"], []):
                handle.write(f"- [{story['title']}]({story['url']}) (score {story['score']})\n")
            handle.write("\n")
    words = sum(len(c["text"].split()) for c in all_chapters)
    log(STAGE, f"{len(all_chapters)} chapters, {words} words, {sum(s.get('used', False) for s in stories)} stories used")


if __name__ == "__main__":
    main()
