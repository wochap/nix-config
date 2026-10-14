"""Stage rank: score items against the interest profile, group same-story items.

usage: briefing-rank --profile profile.json --mode daily|weekly --in items.jsonl --out stories.jsonl

1. Embeddings: each item gets its nearest topic (chapter description) and only
   the `prefilter` items closest to any topic go on.
2. Relevance: $BRIEFING_SCORER (jev or rerank) scores the shortlist against
   the interests; if it fails, the LLM scores the shortlist instead.
3. Editor: the LLM sees only the top `maxStories * 3` and sets topic, hype,
   reason and a newsworthiness score. Jev is calibrated (0-3), so the final
   score averages both; reranker scores only order the shortlist, so the LLM
   score is final. When the scorer already was the LLM, its answer is used as is.
4. Keep items >= threshold (topped up to `minStories`), group same-story items
   by embedding similarity (LLM clustering without embeddings); multi-source
   stories get a small boost. Write the best `maxStories`, highest score first.
"""

import argparse
import json
import os
from concurrent.futures import ThreadPoolExecutor

import numpy as np

from briefing.common import llm_json, log, read_jsonl, read_text, write_jsonl
from briefing.services import TOPIC_INSTRUCT, ServiceError, item_text, jev_scores, rerank_scores, scorer_name, try_embedder

STAGE = "rank"
# Scorers whose 0-1 values mean the same across runs; the others only rank.
CALIBRATED = {"jev"}
BATCH = 40
MAX_ITEMS = 320


def topics_of(profile):
    return {c["key"]: c["description"] for c in profile["chapters"] if c.get("kind", "stories") == "stories"}


def llm_batch(batch, prompt):
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


def llm_rows(items, prompt):
    """{id: row} from the rank prompt, in parallel batches."""
    batches = [items[i : i + BATCH] for i in range(0, len(items), BATCH)]
    with ThreadPoolExecutor(max_workers=4) as pool:
        replies = [row for batch in pool.map(lambda b: llm_batch(b, prompt), batches) for row in batch]
    return {str(row.get("id")): row for row in replies if isinstance(row, dict)}


def to_score(value):
    try:
        score = float(value)
    except (TypeError, ValueError):
        return None
    if score > 1:
        score = score / 10 if score <= 10 else score / 100
    return max(0.0, min(1.0, score))


def scorer_text(item):
    return f"{item['feed']}: {item['title']}\n{item['snippet'][:280]}".strip()


def relevance(items, interests):
    """(scorer name, scores); (llm, None) when the scorer failed and the LLM must score."""
    name = scorer_name()
    texts = [scorer_text(i) for i in items]
    try:
        if name == "jev":
            return name, jev_scores(texts, interests)
        if name == "rerank":
            return name, rerank_scores(texts, f"News that a listener with these interests wants in their briefing:\n{interests}")
        log(STAGE, f"unknown scorer {name!r}, the LLM scores instead")
    except (ServiceError, KeyError, TypeError, ValueError) as error:
        log(STAGE, f"scorer {name} failed, the LLM scores instead: {error}")
    return "llm", None


def apply_row(item, row, topics):
    """Set topic, hype and reason from an LLM row; return its score (None when missing)."""
    score = to_score(row.get("score"))
    item["topic"] = row.get("topic") if row.get("topic") in topics else "skip"
    item["hype"] = bool(row.get("hype"))
    item["reason"] = row.get("reason") or ""
    return score


def cluster_llm(candidates, prompt):
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


def cluster_embedded(candidates, vectors, threshold):
    """Greedy grouping, best score first: an item joins the group whose centroid is closest, if close enough."""
    groups = []  # [members, summed vector]
    for item in sorted(candidates, key=lambda i: -i["score"]):
        vector = vectors[item["id"]]
        best, best_similarity = None, threshold
        for group in groups:
            centroid = group[1] / np.linalg.norm(group[1])
            similarity = float(centroid @ vector)
            if similarity >= best_similarity:
                best, best_similarity = group, similarity
        if best is None:
            groups.append([[item], vector.copy()])
        else:
            log(STAGE, f"same story ({best_similarity:.2f}): {item['title'][:70]!r} -> {best[0][0]['title'][:70]!r}")
            best[0].append(item)
            best[1] += vector
    return [("", members) for members, _ in groups]


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
    max_stories = int(settings["maxStories"])
    threshold = float(settings.get("threshold", 0.6))
    fallback = float(settings.get("fallbackScore", 0.3))
    topic_lines = "\n".join(f"- {key}: {description}" for key, description in topics.items())
    rank_prompt = (
        read_text(os.path.join(args.prompts, "rank.md"))
        .replace("{{interests}}", profile["interests"])
        .replace("{{topics}}", topic_lines)
        .replace("{{mode}}", args.mode)
    )

    # 1. Prefilter by closeness to a topic.
    vectors = {}
    embedder = try_embedder(STAGE)
    if embedder:
        try:
            matrix = embedder.embed([item_text(i["title"], i["snippet"]) for i in items])
            topic_matrix = embedder.embed([TOPIC_INSTRUCT + d for d in topics.values()])
            similarity = matrix @ topic_matrix.T
            keys = list(topics)
            for item, row, vector in zip(items, similarity, matrix):
                item["topic_hint"] = keys[int(row.argmax())]
                item["closeness"] = round(float(row.max()), 3)
                vectors[item["id"]] = vector
            limit = int(settings.get("prefilter", 120))
            items = sorted(items, key=lambda i: -i["closeness"])[:limit]
            log(STAGE, f"prefilter kept {len(items)} items closest to a topic")
        except Exception as error:  # noqa: BLE001 - any embedding failure falls back to the LLM path
            log(STAGE, f"embedding prefilter failed, ranking without it: {error}")
            vectors = {}

    # 2. Relevance, 3. editor pass.
    scorer, values = relevance(items, profile["interests"])
    if values is None:
        rows = llm_rows(items, rank_prompt)
        for item in items:
            score = apply_row(item, rows.get(item["id"], {}), topics)
            item["score"] = fallback if score is None else score
            if score is None:
                item["reason"] = "unscored (fallback)"
        log(STAGE, f"llm scored {len(rows)}/{len(items)} items")
    else:
        for item, value in zip(items, values):
            item["relevance"] = round(value, 3)
        items.sort(key=lambda i: -i["relevance"])
        editors = items[: max_stories * 3]
        rows = llm_rows(editors, rank_prompt)
        for item in items:
            row = rows.get(item["id"])
            if row is None:
                item["score"] = item["relevance"] if scorer in CALIBRATED else fallback
                item["topic"] = item.get("topic_hint", "skip")
                item["hype"] = False
                item["reason"] = f"{scorer} relevance only"
                continue
            news = apply_row(item, row, topics)
            if news is None:
                news = item["relevance"] if scorer in CALIBRATED else fallback
            item["score"] = round((item["relevance"] + news) / 2, 3) if scorer in CALIBRATED else news
        log(STAGE, f"{scorer} scored {len(items)} items, editor reviewed {len(rows)}/{len(editors)}")

    relevant = sorted((i for i in items if i["topic"] != "skip"), key=lambda i: -i["score"])
    candidates = [i for i in relevant if i["score"] >= threshold]
    if len(candidates) < int(settings.get("minStories", 4)):
        candidates = relevant[: int(settings.get("minStories", 4))]
    candidates = candidates[: max_stories * 3]

    # 4. Group same-story items.
    if vectors and all(c["id"] in vectors for c in candidates):
        groups = cluster_embedded(candidates, vectors, float(profile["similarity"]["cluster"]))
    else:
        groups = cluster_llm(candidates, read_text(os.path.join(args.prompts, "cluster.md")))
    stories = [build_story(title, members) for title, members in groups]
    stories.sort(key=lambda s: -s["score"])
    write_jsonl(args.out, stories[:max_stories])
    log(STAGE, f"{len(candidates)} candidates -> {len(stories)} stories, kept {min(len(stories), max_stories)}")


if __name__ == "__main__":
    main()
