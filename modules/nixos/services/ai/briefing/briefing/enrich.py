"""Stage enrich: corroborate the top stories with SearXNG, then scrape full text with Firecrawl.

usage: briefing-enrich --in stories.jsonl --out enriched.jsonl [--top N] [--corroborate N]
                       [--time-range day|week|month] [--similarity 0.75] [--max-chars 5000]

1. Corroborate: the best --corroborate stories that only one feed reported are
   searched on SearXNG (news category, within --time-range). Results whose
   embedding is at least --similarity close to the story join its sources
   (`via: "searxng"`), up to two per story.
2. Scrape: for the best --top stories, each source URL is scraped in order
   until one gives enough text; stories that fail keep their snippets.
"""

import argparse
import re
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

from briefing.common import canonical_url, log, read_jsonl, write_jsonl
from briefing.services import ServiceError, firecrawl_scrape, item_text, searxng_search, try_embedder

STAGE = "enrich"
# Short-form posts, videos and discussion pages: the feed snippet already is the content.
SKIP_HOSTS = ("x.com", "twitter.com", "youtube.com", "youtu.be", "news.ycombinator.com", "reddit.com")
# Less text than this is a paywall, cookie wall or error page, not an article.
MIN_CHARS = 400
MAX_EXTRA_SOURCES = 2


def host_of(url):
    return urlsplit(url or "").netloc.lower().removeprefix("www.")


def skipped(url):
    host = host_of(url)
    return not url or any(host == h or host.endswith("." + h) for h in SKIP_HOSTS)


def search_queries(title):
    """The title as a search query, then a shorter one: no retweet prefix, URLs or wire-service tails."""
    text = re.sub(r"^RT [^:]{1,40}:\s*", "", title)
    text = re.sub(r"https?://\S+|\([^)]*\)|[@#]", " ", text)
    text = re.sub(r":\s*(Markets Wrap|Live Updates?|Report|Analysis)\b.*$", "", text, flags=re.I)
    words = text.split()
    return list(dict.fromkeys(q for q in (" ".join(words[:14]), " ".join(words[:7])) if q))


def corroborate(stories, embedder, time_range, threshold):
    def search(story):
        for query in search_queries(story["title"]):
            try:
                hits = searxng_search(query, time_range=time_range)
            except ServiceError as error:
                log(STAGE, f"search failed for {query[:60]!r}: {error}")
                return []
            if hits:
                return hits
        return []

    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(search, stories))
    added = 0
    for story, hits in zip(stories, results):
        known = {canonical_url(s.get("url", "")) for s in story["sources"]}
        outlets = {host_of(s.get("url", "")) for s in story["sources"]}
        hits = [h for h in hits if canonical_url(h["url"]) not in known and host_of(h["url"]) not in outlets and not skipped(h["url"])]
        if not hits:
            continue
        try:
            vectors = embedder.embed([item_text(story["title"], story.get("snippet", ""))] + [item_text(h.get("title", ""), h.get("content", "")) for h in hits])
        except Exception as error:  # noqa: BLE001 - corroboration is optional
            log(STAGE, f"embedding failed, no corroboration: {error}")
            return added
        similarity = vectors[1:] @ vectors[0]
        ranked = sorted(zip(hits, similarity), key=lambda pair: -pair[1])
        for hit, value in ranked[:MAX_EXTRA_SOURCES]:
            if value < threshold:
                break
            story["sources"].append(
                {"feed": host_of(hit["url"]), "title": hit.get("title", ""), "url": hit["url"], "snippet": (hit.get("content") or "")[:400], "via": "searxng"}
            )
            added += 1
    return added


def scrape(url, timeout):
    if skipped(url):
        return None
    try:
        article = firecrawl_scrape(url, timeout=timeout)
    except ServiceError as error:
        log(STAGE, f"failed: {url}: {error}")
        return None
    return article if len(article["body"]) >= MIN_CHARS else None


def enrich(story, max_chars, timeout):
    if story.get("body"):
        return story
    for source in story.get("sources", []) or [{"url": story.get("url", "")}]:
        article = scrape(source.get("url", ""), timeout)
        if article:
            story["body"] = article["body"][:max_chars]
            story["body_url"] = canonical_url(article["url"]) or source["url"]
            break
    return story


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--in", dest="input", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--top", type=int, default=12)
    parser.add_argument("--corroborate", type=int, default=6)
    parser.add_argument("--time-range", default="week", choices=["day", "week", "month"])
    parser.add_argument("--similarity", type=float, default=0.75)
    parser.add_argument("--max-chars", type=int, default=5000)
    parser.add_argument("--timeout", type=int, default=60)
    args = parser.parse_args()

    stories = read_jsonl(args.input)
    lonely = [s for s in stories[: args.corroborate] if len({src.get("feed") for src in s.get("sources", [])}) < 2]
    embedder = try_embedder(STAGE) if lonely else None
    if embedder:
        log(STAGE, f"corroboration added {corroborate(lonely, embedder, args.time_range, args.similarity)} sources to {len(lonely)} single-source stories")

    head, tail = stories[: args.top], stories[args.top :]
    with ThreadPoolExecutor(max_workers=4) as pool:
        head = list(pool.map(lambda s: enrich(s, args.max_chars, args.timeout), head))
    write_jsonl(args.out, head + tail)
    log(STAGE, f"{sum(bool(s.get('body')) for s in head)}/{len(head)} stories have full text")


if __name__ == "__main__":
    main()
