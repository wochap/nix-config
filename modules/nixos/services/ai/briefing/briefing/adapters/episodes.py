"""Items adapter: stories ranked by previous episodes (feeds the weekly recap).

Config: {key, root=$BRIEFING_OUT_DIR, sourceMode="daily", days=7}
Reads <root>/<date>-<mode>/stories.jsonl for the last `days` days.
"""

import json
import os
import sys
from datetime import date, timedelta

from briefing.common import log, make_item, read_jsonl

STAGE = "source:episodes"


def main():
    config = json.load(sys.stdin)
    root = os.path.expanduser(config.get("root") or os.environ.get("BRIEFING_OUT_DIR", "~/Sync/podcasts"))
    source_mode = config.get("sourceMode", "daily")
    oldest = date.today() - timedelta(days=int(config.get("days", 7)))
    count = 0
    for name in sorted(os.listdir(root)) if os.path.isdir(root) else []:
        day, _, mode = name.partition("-" + source_mode)
        if mode or not _ or day < oldest.isoformat():
            continue
        for story in read_jsonl(os.path.join(root, name, "stories.jsonl")):
            item = make_item(
                config["key"],
                title=story["title"],
                url=story.get("url", ""),
                section=story.get("topic", ""),
                feed=", ".join(sorted({s.get("feed", "") for s in story.get("sources", [])})) or story.get("feed", ""),
                published=story.get("published", ""),
                snippet=story.get("summary") or story.get("snippet", ""),
                episode=name,
                previous_score=story.get("score"),
                previously_used=story.get("used", False),
                body=story.get("body", ""),
            )
            print(json.dumps(item, ensure_ascii=False))
            count += 1
    log(STAGE, f"{count} stories from previous {source_mode} episodes since {oldest}")


if __name__ == "__main__":
    main()
