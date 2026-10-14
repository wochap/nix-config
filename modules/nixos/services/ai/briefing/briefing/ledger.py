"""Ledger of stories already used in an episode (SQLite, local, rebuildable).

usage:
  briefing-ledger record --ledger DB --episode NAME --mode MODE --stories stories.jsonl
  briefing-ledger rebuild --ledger DB --root ~/Sync/podcasts
  briefing-ledger seen --ledger DB --mode MODE [--exclude-episode NAME]
                       [--similarity 0.88 --days 10] < items.jsonl > new.jsonl
  briefing-ledger search --ledger DB TEXT

Keys are hashes of the canonical URL and of the normalized title, so the same
story is caught even when it comes back from a different feed. Every source
of a used story also gets an embedding: `seen` drops an item whose embedding
is at least --similarity close to one used in the last --days days (a
rewritten headline of a story already told). Without the embedding service it
checks the hashes only.
"""

import argparse
import json
import os
import sqlite3
import sys
from datetime import timedelta

import numpy as np

from briefing.common import canonical_url, iso, log, now_utc, read_jsonl, sha, title_key
from briefing.services import item_text, try_embedder

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
CREATE TABLE IF NOT EXISTS used_vectors (
  mode TEXT NOT NULL,
  episode TEXT NOT NULL,
  title TEXT,
  vector BLOB NOT NULL
);
CREATE INDEX IF NOT EXISTS used_vectors_mode ON used_vectors (mode, episode);
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


def story_texts(story):
    sources = story.get("sources") or [{"title": story.get("title", ""), "snippet": story.get("snippet", "")}]
    return list(dict.fromkeys(item_text(s.get("title", ""), s.get("snippet", "")) for s in sources if s.get("title")))


def record_vectors(db, embedder, episode, mode, stories):
    db.execute("DELETE FROM used_vectors WHERE episode = ? AND mode = ?", (episode, mode))
    entries = [(story.get("title", ""), text) for story in stories if story.get("used") for text in story_texts(story)]
    if not embedder or not entries:
        return
    try:
        matrix = embedder.embed([text for _, text in entries])
    except Exception as error:  # noqa: BLE001 - the hash keys still work without vectors
        log(STAGE, f"no vectors recorded for {episode}: {error}")
        return
    db.executemany(
        "INSERT INTO used_vectors VALUES (?, ?, ?, ?)",
        [(mode, episode, title, vector.tobytes()) for (title, _), vector in zip(entries, matrix)],
    )


def record(db, episode, mode, stories, embedder=None):
    stamp = iso(now_utc())
    db.execute("DELETE FROM used WHERE episode = ? AND mode = ?", (episode, mode))
    record_vectors(db, embedder, episode, mode, stories)
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


def drop_similar(db, items, args):
    """Drop items whose embedding is close to a story used in the last `days` days."""
    # Episode names start with their date, so a string comparison selects the window.
    cutoff = (now_utc() - timedelta(days=args.days)).strftime("%Y-%m-%d")
    rows = db.execute(
        "SELECT title, vector FROM used_vectors WHERE mode = ? AND episode != ? AND episode >= ?",
        (args.mode, args.exclude_episode, cutoff),
    ).fetchall()
    embedder = try_embedder(STAGE) if rows and items else None
    if not embedder:
        return items
    try:
        matrix = embedder.embed([item_text(i.get("title", ""), i.get("snippet", "")) for i in items])
        used = np.stack([np.frombuffer(blob, dtype=np.float32) for _, blob in rows])
        if used.shape[1] != matrix.shape[1]:
            log(STAGE, "embedding model changed since these stories were recorded; run `briefing ledger rebuild`")
            return items
    except Exception as error:  # noqa: BLE001 - fall back to the hash check alone
        log(STAGE, f"embedding check skipped: {error}")
        return items
    similarity = matrix @ used.T
    kept = []
    for item, row in zip(items, similarity):
        best = int(row.argmax())
        if row[best] >= args.similarity:
            log(STAGE, f"already told ({row[best]:.2f}): {item.get('title', '')[:70]!r} ~ {rows[best][0][:70]!r}")
        else:
            kept.append(item)
    log(STAGE, f"embedding check dropped {len(items) - len(kept)} items against {len(rows)} recent stories")
    return kept


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
    parser.add_argument("--similarity", type=float, default=0.88, help="embedding cosine at which an item counts as already told")
    parser.add_argument("--days", type=int, default=10, help="how far back the embedding check looks")
    args = parser.parse_args()
    db = connect(args.ledger)

    if args.command == "record":
        count = record(db, args.episode, args.mode, read_jsonl(args.stories), try_embedder(STAGE))
        log(STAGE, f"recorded {count} stories for {args.episode}")
    elif args.command == "rebuild":
        db.execute("DELETE FROM used")
        db.execute("DELETE FROM used_vectors")
        embedder = try_embedder(STAGE)
        total = 0
        for name in sorted(os.listdir(args.root)):
            mode = name.rsplit("-", 1)[-1]
            path = os.path.join(args.root, name, "stories.jsonl")
            if os.path.exists(path):
                total += record(db, name, mode, read_jsonl(path), embedder)
        log(STAGE, f"rebuilt ledger with {total} stories")
    elif args.command == "seen":
        items = [json.loads(line) for line in sys.stdin if line.strip()]
        fresh = [
            item
            for item in items
            if not any(
                db.execute("SELECT 1 FROM used WHERE key = ? AND mode = ? AND episode != ? LIMIT 1", (key, args.mode, args.exclude_episode)).fetchone()
                for _, key in keys_for(item.get("title", ""), item.get("url", ""))
            )
        ]
        log(STAGE, f"hash check dropped {len(items) - len(fresh)} of {len(items)} items")
        fresh = drop_similar(db, fresh, args)
        for item in fresh:
            sys.stdout.write(json.dumps(item, ensure_ascii=False) + "\n")
        log(STAGE, f"kept {len(fresh)} new items for {args.mode}")
    elif args.command == "search":
        pattern = f"%{args.text or ''}%"
        for row in db.execute("SELECT DISTINCT episode, title, url FROM used WHERE title LIKE ? OR url LIKE ? ORDER BY episode", (pattern, pattern)):
            print("\t".join(str(v or "") for v in row))


if __name__ == "__main__":
    main()
