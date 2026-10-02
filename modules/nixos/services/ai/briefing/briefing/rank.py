"""Stage rank: score items against the interest profile, group same-story items.

usage: briefing-rank --profile profile.json --mode daily|weekly --in items.jsonl --out stories.jsonl

1. Batched LLM scoring -> {id, score 0..1, topic, hype, reason} (scores are
   aligned by id; unscored items get `fallbackScore`).
2. Keep items >= threshold, topped up to `minStories`, capped to 3x `maxStories`.
3. One LLM call groups items about the same story; each story keeps every
   source, and multi-source stories get a small score boost.
4. Write the best `maxStories` stories, highest score first.
"""

import argparse
import json
import os
from concurrent.futures import ThreadPoolExecutor

from briefing.common import llm_json, log, read_jsonl, read_text, write_jsonl

STAGE = "rank"
BATCH = 40
MAX_ITEMS = 320


def topics_of(profile):
    return {c["key"]: c["description"] for c in profile["chapters"] if c.get("kind", "stories") == "stories"}


def score_batch(batch, profile, mode, prompt):
    payload = [
        {"id": i["id"], "feed": i["feed"], "section": i["section"], "title": i["title"], "snippet": i["snippet"][:280]}
        for i in batch
    ]
    messages = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
    ]
    try:
        reply = llm_json(messages, temperature=0.1, stage=STAGE)
    except RuntimeError as error:
        log(STAGE, f"batch failed: {error}")
        return []
    if isinstance(reply, dict):
        reply = reply.get("items") or reply.get("results") or []
    return reply if isinstance(reply, list) else []


def to_score(value):
    try:
        score = float(value)
    except (TypeError, ValueError):
        return None
    if score > 1:
        score = score / 10 if score <= 10 else score / 100
    return max(0.0, min(1.0, score))


def cluster(candidates, prompt):
    payload = [{"id": i["id"], "feed": i["feed"], "title": i["title"]} for i in candidates]
    messages = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
    ]
    try:
        groups = llm_json(messages, temperature=0.1, stage=STAGE)
    except RuntimeError as error:
        log(STAGE, f"clustering failed, one story per item: {error}")
        groups = []
    if isinstance(groups, dict):
        groups = groups.get("groups") or groups.get("stories") or []
    by_id = {i["id"]: i for i in candidates}
    seen, stories = set(), []
    for group in groups if isinstance(groups, list) else []:
        ids = [i for i in group.get("ids", []) if i in by_id and i not in seen]
        if ids:
            seen.update(ids)
            stories.append((group.get("title", ""), [by_id[i] for i in ids]))
    stories += [("", [item]) for item in candidates if item["id"] not in seen]
    return stories


def build_story(title, members):
    members = sorted(members, key=lambda i: -i["score"])
    lead = members[0]
    score = min(1.0, lead["score"] + 0.05 * (len({m["feed"] for m in members}) - 1))
    return {
        "id": lead["id"],
        "title": title or lead["title"],
        "url": lead["url"],
        "topic": lead["topic"],
        "hype": any(m.get("hype") for m in members),
        "score": round(score, 3),
        "reason": lead.get("reason", ""),
        "published": max(m.get("published", "") for m in members),
        "snippet": lead["snippet"],
        "body": next((m["body"] for m in members if m.get("body")), ""),
        "sources": [{"feed": m["feed"], "title": m["title"], "url": m["url"], "snippet": m["snippet"][:400]} for m in members],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--mode", default="daily")
    parser.add_argument("--in", dest="input", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--prompts", default=os.environ.get("BRIEFING_PROMPTS", ""))
    args = parser.parse_args()

    with open(args.profile, encoding="utf-8") as handle:
        profile = json.load(handle)
    settings = profile[args.mode]
    items = sorted(read_jsonl(args.input), key=lambda i: i.get("published", ""), reverse=True)[:MAX_ITEMS]
    if not items:
        write_jsonl(args.out, [])
        log(STAGE, "no items to rank")
        return

    topics = topics_of(profile)
    topic_lines = "\n".join(f"- {key}: {description}" for key, description in topics.items())
    score_prompt = (
        read_text(os.path.join(args.prompts, "rank.md"))
        .replace("{{interests}}", profile["interests"])
        .replace("{{topics}}", topic_lines)
        .replace("{{mode}}", args.mode)
    )

    batches = [items[i : i + BATCH] for i in range(0, len(items), BATCH)]
    with ThreadPoolExecutor(max_workers=4) as pool:
        replies = [row for batch in pool.map(lambda b: score_batch(b, profile, args.mode, score_prompt), batches) for row in batch]

    scored = {str(row.get("id")): row for row in replies if isinstance(row, dict)}
    fallback = float(settings.get("fallbackScore", 0.3))
    for item in items:
        row = scored.get(item["id"], {})
        score = to_score(row.get("score"))
        item["score"] = fallback if score is None else score
        item["topic"] = row.get("topic") if row.get("topic") in topics else "skip"
        item["hype"] = bool(row.get("hype"))
        item["reason"] = row.get("reason") or ("unscored (fallback)" if score is None else "")
    log(STAGE, f"scored {len(scored)}/{len(items)} items in {len(batches)} batches")

    relevant = sorted((i for i in items if i["topic"] != "skip"), key=lambda i: -i["score"])
    threshold = float(settings.get("threshold", 0.6))
    max_stories = int(settings["maxStories"])
    candidates = [i for i in relevant if i["score"] >= threshold]
    if len(candidates) < int(settings.get("minStories", 4)):
        candidates = relevant[: int(settings.get("minStories", 4))]
    candidates = candidates[: max_stories * 3]

    cluster_prompt = read_text(os.path.join(args.prompts, "cluster.md"))
    stories = [build_story(title, members) for title, members in cluster(candidates, cluster_prompt)]
    stories.sort(key=lambda s: -s["score"])
    write_jsonl(args.out, stories[:max_stories])
    log(STAGE, f"{len(candidates)} candidates -> {len(stories)} stories, kept {min(len(stories), max_stories)}")


if __name__ == "__main__":
    main()
