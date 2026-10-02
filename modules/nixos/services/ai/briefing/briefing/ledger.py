"""Ledger of stories already used in an episode (SQLite, local, rebuildable).

usage:
  briefing-ledger record --ledger DB --episode NAME --mode MODE --stories stories.jsonl
  briefing-ledger rebuild --ledger DB --root ~/Sync/podcasts
  briefing-ledger seen --ledger DB --mode MODE [--exclude-episode NAME] < items.jsonl > new.jsonl
  briefing-ledger search --ledger DB TEXT

Keys are hashes of the canonical URL and of the normalized title, so the same
story is caught even when it comes back from a different feed.
"""

import argparse
import json
import os
import sqlite3
import sys

from briefing.common import canonical_url, iso, log, now_utc, read_jsonl, sha, title_key

STAGE = "ledger"
SCHEMA = """
CREATE TABLE IF NOT EXISTS used (
  key TEXT NOT NULL,
  kind TEXT NOT NULL,
  mode TEXT NOT NULL,
  episode TEXT NOT NULL,
  title TEXT,
  url TEXT,
  score REAL,
  recorded_at TEXT,
  PRIMARY KEY (key, mode, episode)
);
CREATE INDEX IF NOT EXISTS used_key ON used (key, mode);
"""


def connect(path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    db = sqlite3.connect(path)
    db.executescript(SCHEMA)
    return db


def keys_for(title, url):
    keys = []
    if url:
        keys.append(("url", sha(canonical_url(url))))
    if title_key(title):
        keys.append(("title", sha(title_key(title))))
    return keys


def story_keys(story):
    entries = [(story.get("title", ""), story.get("url", ""))]
    entries += [(s.get("title", ""), s.get("url", "")) for s in story.get("sources", [])]
    return {key for title, url in entries for key in keys_for(title, url)}


def record(db, episode, mode, stories):
    stamp = iso(now_utc())
    db.execute("DELETE FROM used WHERE episode = ? AND mode = ?", (episode, mode))
    count = 0
    for story in stories:
        if not story.get("used"):
            continue
        for kind, key in story_keys(story):
            db.execute(
                "INSERT OR REPLACE INTO used VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (key, kind, mode, episode, story.get("title"), story.get("url"), story.get("score"), stamp),
            )
        count += 1
    db.commit()
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["record", "rebuild", "seen", "search"])
    parser.add_argument("text", nargs="?")
    parser.add_argument("--ledger", default=os.path.expanduser("~/.local/state/briefing/ledger.db"))
    parser.add_argument("--episode")
    parser.add_argument("--mode", default="daily")
    parser.add_argument("--stories")
    parser.add_argument("--root", default=os.path.expanduser("~/Sync/podcasts"))
    parser.add_argument("--exclude-episode", default="")
    args = parser.parse_args()
    db = connect(args.ledger)

    if args.command == "record":
        count = record(db, args.episode, args.mode, read_jsonl(args.stories))
        log(STAGE, f"recorded {count} stories for {args.episode}")
    elif args.command == "rebuild":
        db.execute("DELETE FROM used")
        total = 0
        for name in sorted(os.listdir(args.root)):
            mode = name.rsplit("-", 1)[-1]
            path = os.path.join(args.root, name, "stories.jsonl")
            if os.path.exists(path):
                total += record(db, name, mode, read_jsonl(path))
        log(STAGE, f"rebuilt ledger with {total} stories")
    elif args.command == "seen":
        kept = dropped = 0
        for line in sys.stdin:
            if not line.strip():
                continue
            item = json.loads(line)
            hits = [
                key
                for _, key in keys_for(item.get("title", ""), item.get("url", ""))
                if db.execute("SELECT 1 FROM used WHERE key = ? AND mode = ? AND episode != ? LIMIT 1", (key, args.mode, args.exclude_episode)).fetchone()
            ]
            if hits:
                dropped += 1
                continue
            sys.stdout.write(line)
            kept += 1
        log(STAGE, f"kept {kept}, dropped {dropped} already used in {args.mode} episodes")
    elif args.command == "search":
        pattern = f"%{args.text or ''}%"
        for row in db.execute("SELECT DISTINCT episode, title, url FROM used WHERE title LIKE ? OR url LIKE ? ORDER BY episode", (pattern, pattern)):
            print("\t".join(str(v or "") for v in row))


if __name__ == "__main__":
    main()
