#!/usr/bin/env python3
"""Store rendered HTML pages and keep their list pages up to date.

The library is the only component that knows where pages live. Layout under
ARTICLE_LIBRARY_DIR (default: $XDG_DATA_HOME/article-library):

    index.html              list of summaries, grouped by day (served at /)
    summaries/<id>.html     summary pages, each with a <id>.json record
    pages/index.html        list of pages from `article render`
    pages/<id>.html
    errors/<id>.html        failure pages, never listed

A page's id is derived from its key (the article URL, or the Markdown file
path), so adding the same key again replaces the page.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

# Collection name -> its list page (relative to the root), title and empty-list message;
# None means unlisted.
COLLECTIONS = {
    "summaries": ("index.html", "Article summaries", "No summaries yet. Summarised articles will appear here, newest day first."),
    "pages": ("pages/index.html", "Rendered pages", "No rendered pages yet. Pages from `article render` will appear here, newest day first."),
    "errors": None,
}


def data_home():
    return Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")


ROOT = Path(os.environ.get("ARTICLE_LIBRARY_DIR") or data_home() / "article-library")
BASE_URL = os.environ.get("ARTICLE_LIBRARY_URL", "").rstrip("/")


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def page_id(key):
    return hashlib.sha256(key.encode()).hexdigest()[:16]


def location(collection, identifier):
    path = ROOT / collection / f"{identifier}.html"
    url = f"{BASE_URL}/{collection}/{identifier}.html" if BASE_URL else path.as_uri()
    return {"id": identifier, "collection": collection, "path": str(path), "url": url}


def write_atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("wb", dir=path.parent, prefix=".", delete=False) as handle:
        handle.write(data)
    os.replace(handle.name, path)


def store(collection, key, page_html, metadata):
    identifier = page_id(key)
    record = {"title": "Untitled", "source": "", "author": "", **metadata}
    record.update(id=identifier, key=key, added_at=now())
    folder = ROOT / collection
    write_atomic(folder / f"{identifier}.json", (json.dumps(record, ensure_ascii=False, indent=2) + "\n").encode())
    write_atomic(folder / f"{identifier}.html", page_html)
    return identifier


# --- list pages -------------------------------------------------------------


def markdown_text(value):
    value = re.sub(r"[\r\n]+", " ", str(value)).strip()
    return re.sub(r"([\\`*_{}\[\]()<>#+.!|~-])", r"\\\1", value)


def added(record):
    try:
        return datetime.fromisoformat(record["added_at"]).astimezone()
    except (KeyError, TypeError, ValueError):
        return datetime.fromtimestamp(0).astimezone()


def records(collection):
    for sidecar in (ROOT / collection).glob("*.json"):
        if not sidecar.with_suffix(".html").exists():
            continue
        try:
            yield json.loads(sidecar.read_text(encoding="utf-8"))
        except ValueError:
            print(f"article-library: skipping unreadable {sidecar}", file=sys.stderr)


def render_list(collection, list_path, title, empty_message):
    """Markdown for one list page; the stylesheet keys list layout on the .nav block."""
    here = (ROOT / list_path).parent
    links = [
        f"[{entry[1]}]({os.path.relpath(ROOT / entry[0], here)})"
        for name, entry in COLLECTIONS.items()
        if entry and name != collection
    ]
    lines = ["::: nav", " · ".join(links), ":::", ""]
    entries = sorted(records(collection), key=added, reverse=True)
    days = {}
    for record in entries:
        days.setdefault(added(record).date(), []).append(record)
    for day, day_records in days.items():
        lines += ["", f"## {day.strftime('%A, %-d %B %Y')} {{count=\"{len(day_records)}\"}}", ""]
        for record in day_records:
            href = os.path.relpath(ROOT / collection / f"{record['id']}.html", here)
            spans = "".join(f" [{markdown_text(record[field])}]{{.{field}}}" for field in ("source", "author") if record.get(field))
            lines.append(f"- [{markdown_text(record.get('title') or 'Untitled')}]({href}){spans}")
    if not entries:
        lines += ["::: empty", empty_message, ":::"]

    with tempfile.TemporaryDirectory() as work_dir:
        markdown = Path(work_dir, "list.md")
        markdown.write_text("\n".join(lines) + "\n", encoding="utf-8")
        page = Path(work_dir, "list.html")
        subprocess.run(
            ["article-render", "--title", title, "--output", str(page), str(markdown)],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        write_atomic(ROOT / list_path, page.read_bytes())


def rebuild(collection=None):
    for name, entry in COLLECTIONS.items():
        if entry and collection in (None, name):
            render_list(name, *entry)


# --- commands ---------------------------------------------------------------


def command_add(args):
    metadata = json.loads(Path(args.meta).read_text(encoding="utf-8")) if args.meta else {}
    identifier = store(args.collection, args.key, Path(args.page).read_bytes(), metadata)
    rebuild(args.collection)
    print(json.dumps(location(args.collection, identifier)))


def command_lookup(args):
    found = location(args.collection, page_id(args.key))
    if not Path(found["path"]).exists():
        return 1
    print(json.dumps(found))


def command_index(_args):
    rebuild()
    print(f"{BASE_URL}/" if BASE_URL else (ROOT / "index.html").as_uri())


def main():
    parser = argparse.ArgumentParser(prog="article-library", description=__doc__.split("\n\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)

    add = commands.add_parser("add", help="store PAGE and print its location as JSON")
    add.add_argument("--collection", choices=COLLECTIONS, required=True)
    add.add_argument("--key", required=True, help="identity of the page, e.g. the article URL")
    add.add_argument("--meta", help="JSON object with title, source, author and any extra fields")
    add.add_argument("page", help="rendered HTML file")
    add.set_defaults(run=command_add)

    lookup = commands.add_parser("lookup", help="print the location of KEY as JSON, exit 1 when absent")
    lookup.add_argument("--collection", choices=COLLECTIONS, required=True)
    lookup.add_argument("--key", required=True)
    lookup.set_defaults(run=command_lookup)

    index = commands.add_parser("index", help="rebuild every list page and print the library URL")
    index.set_defaults(run=command_index)

    args = parser.parse_args()
    return args.run(args)


if __name__ == "__main__":
    sys.exit(main())
