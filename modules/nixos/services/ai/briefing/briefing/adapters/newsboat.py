"""Items adapter: reload newsboat, then read recent articles from its cache.db.

Config: {key, since="24h", tags=[...], urlsFile, cacheFile, reload=true, reloadTimeout=300}
Feed tags come from the newsboat urls file (`URL "~Name" Tag ...`); an empty
`tags` list keeps every feed.
"""

import json
import os
import shlex
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone

from briefing.common import log, make_item, now_utc, parse_duration

STAGE = "source:newsboat"


def parse_urls(path):
    """Map feed URL -> (display name, set of tags) from a newsboat urls file."""
    feeds = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                parts = shlex.split(line)
            except ValueError:
                parts = line.split()
            url, rest = parts[0], parts[1:]
            name = next((p[1:] for p in rest if p.startswith("~")), "")
            tags = {p for p in rest if not p.startswith(("~", "!"))}
            feeds[url] = (name, tags)
    return feeds


def reload(config):
    command = ["newsboat", "-x", "reload", "-q", "-u", config["urlsFile"], "-c", config["cacheFile"]]
    if config.get("configFile"):
        command += ["-C", config["configFile"]]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=config.get("reloadTimeout", 300), check=False)
    except subprocess.TimeoutExpired:
        log(STAGE, "reload timed out, using existing cache")
        return
    if result.returncode != 0:
        # Usually the TUI holds cache.db.lock; it auto-reloads on its own.
        reason = (result.stderr or result.stdout).strip().splitlines()
        log(STAGE, f"reload failed ({reason[-1] if reason else result.returncode}), using existing cache")


def main():
    config = json.load(sys.stdin)
    home = os.path.expanduser("~")
    config.setdefault("urlsFile", f"{home}/.config/newsboat/urls")
    config.setdefault("cacheFile", f"{home}/.local/share/newsboat/cache.db")
    wanted = set(config.get("tags") or [])

    if config.get("reload", True):
        reload(config)

    feeds = parse_urls(config["urlsFile"])
    selected = {url: meta for url, meta in feeds.items() if not wanted or meta[1] & wanted}
    since = int((now_utc() - parse_duration(config.get("since", "24h"))).timestamp())

    db = sqlite3.connect(f"file:{config['cacheFile']}?mode=ro", uri=True, timeout=30)
    rows = db.execute(
        "SELECT feedurl, title, url, author, pubDate, content FROM rss_item WHERE deleted = 0 AND pubDate >= ? ORDER BY pubDate DESC",
        (since,),
    ).fetchall()
    db.close()

    count = 0
    for feedurl, title, url, author, pub, content in rows:
        meta = selected.get(feedurl)
        if not meta or not title:
            continue
        name, tags = meta
        section = sorted(tags & wanted)[0] if wanted else (sorted(tags)[0] if tags else "")
        item = make_item(
            config["key"],
            title=title,
            url=url,
            section=section,
            feed=name or feedurl,
            published=datetime.fromtimestamp(pub, timezone.utc),
            snippet=content or "",
            author=author or "",
        )
        print(json.dumps(item, ensure_ascii=False))
        count += 1
    log(STAGE, f"{count} items from {len(selected)} feeds")


if __name__ == "__main__":
    main()
