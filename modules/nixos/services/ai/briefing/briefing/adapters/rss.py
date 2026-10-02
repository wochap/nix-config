"""Items adapter: fetch RSS/Atom feeds directly.

Config: {key, since="24h", feeds=[{url, title, section}], limit=40}
"""

import calendar
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

import feedparser

from briefing.common import http_get, log, make_item, now_utc, parse_duration

STAGE = "source:rss"


def fetch(feed, since, limit, key):
    try:
        parsed = feedparser.parse(http_get(feed["url"], timeout=20))
    except Exception as error:  # noqa: BLE001
        log(STAGE, f"{feed['url']}: {error}")
        return []
    items = []
    for entry in parsed.entries[:limit]:
        stamp = entry.get("published_parsed") or entry.get("updated_parsed")
        published = datetime.fromtimestamp(calendar.timegm(stamp), timezone.utc) if stamp else None
        if published and published < since:
            continue
        items.append(
            make_item(
                key,
                title=entry.get("title", ""),
                url=entry.get("link", ""),
                section=feed.get("section", ""),
                feed=feed.get("title") or parsed.feed.get("title", feed["url"]),
                published=published or now_utc(),
                snippet=entry.get("summary", ""),
            )
        )
    return items


def main():
    config = json.load(sys.stdin)
    since = now_utc() - parse_duration(config.get("since", "24h"))
    limit = int(config.get("limit", 40))
    feeds = config.get("feeds", [])
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda feed: fetch(feed, since, limit, config["key"]), feeds))
    count = 0
    for items in results:
        for item in items:
            print(json.dumps(item, ensure_ascii=False))
            count += 1
    log(STAGE, f"{count} items from {len(feeds)} feeds")


if __name__ == "__main__":
    main()
