"""Shared logic for the generic adapters (command, http-json, file-json).

Raw JSON is optionally reshaped by a `jq` filter, then normalized:
- kind "items": the result must be an array (or a stream) of objects with at
  least `title`; known fields (url, section, feed, published, snippet) are kept,
  anything else is preserved as extra fields.
- kind "facts": the result must be an object; `highlights` (list of strings)
  and `sections` ([{title, rows}]) are optional.
"""

import json
import subprocess

from briefing.common import iso, log, make_item, now_utc

KNOWN = ("title", "url", "section", "feed", "published", "snippet")


def apply_jq(raw, expression):
    if not expression:
        return json.loads(raw)
    result = subprocess.run(["jq", "-c", expression], input=raw, capture_output=True, text=True, check=True)
    values = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
    return values[0] if len(values) == 1 else values


def emit(config, raw, stage):
    value = apply_jq(raw, config.get("jq"))
    if config.get("kind", "items") == "facts":
        if not isinstance(value, dict):
            raise ValueError("facts adapter output must be a JSON object")
        value.setdefault("title", config["key"])
        value.setdefault("asof", iso(now_utc()))
        value.setdefault("highlights", [])
        value.setdefault("sections", [])
        value["source"] = config["key"]
        print(json.dumps(value, ensure_ascii=False))
        log(stage, f"facts with {len(value['highlights'])} highlights")
        return
    rows = value if isinstance(value, list) else [value]
    count = 0
    for row in rows:
        if not isinstance(row, dict) or not row.get("title"):
            continue
        extra = {k: v for k, v in row.items() if k not in KNOWN and k not in ("id", "source", "canonical_url")}
        item = make_item(
            config["key"],
            title=row["title"],
            url=row.get("url", ""),
            section=row.get("section") or config.get("section", ""),
            feed=row.get("feed") or config.get("feed", config["key"]),
            published=row.get("published") or iso(now_utc()),
            snippet=row.get("snippet", ""),
            **extra,
        )
        print(json.dumps(item, ensure_ascii=False))
        count += 1
    log(stage, f"{count} items")
