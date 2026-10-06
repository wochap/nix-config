"""Stage enrich: fetch full article text for the top stories via `article scrape`.

usage: briefing-enrich --in stories.jsonl --out enriched.jsonl [--top N] [--max-chars 5000]

Only ranked winners are scraped. Each source URL of a story is tried in order
until one extracts; stories that fail keep their RSS snippets.
"""

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

from briefing.common import log, read_jsonl, write_jsonl

STAGE = "enrich"
# Short-form posts and videos: the feed snippet already is the content.
SKIP_HOSTS = ("x.com", "twitter.com", "youtube.com", "youtu.be", "github.com", "news.ycombinator.com")


def scrape(url, timeout):
    host = urlsplit(url).netloc.lower().removeprefix("www.")
    if not url or any(host == h or host.endswith("." + h) for h in SKIP_HOSTS):
        return None
    try:
        result = subprocess.run(["article", "scrape", url], capture_output=True, text=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        log(STAGE, f"timeout: {url}")
        return None
    if result.returncode != 0:
        log(STAGE, f"failed: {url}")
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


def enrich(story, max_chars, timeout):
    if story.get("body"):
        return story
    for source in story.get("sources", []) or [{"url": story.get("url", "")}]:
        article = scrape(source.get("url", ""), timeout)
        if article and article.get("body"):
            story["body"] = article["body"][:max_chars]
            story["body_url"] = article.get("canonical_url") or source["url"]
            break
    return story


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--in", dest="input", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--top", type=int, default=12)
    parser.add_argument("--max-chars", type=int, default=5000)
    parser.add_argument("--timeout", type=int, default=90)
    args = parser.parse_args()

    stories = read_jsonl(args.input)
    head, tail = stories[: args.top], stories[args.top :]
    with ThreadPoolExecutor(max_workers=4) as pool:
        head = list(pool.map(lambda s: enrich(s, args.max_chars, args.timeout), head))
    write_jsonl(args.out, head + tail)
    log(STAGE, f"{sum(bool(s.get('body')) for s in head)}/{len(head)} stories have full text")


if __name__ == "__main__":
    main()
