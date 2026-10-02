"""Generic adapter: read a JSON file (e.g. output dropped by another tool).

Config: {key, kind="items"|"facts", path, jq?}
"""

import json
import os
import sys

from briefing.adapters.generic import emit


def main():
    config = json.load(sys.stdin)
    with open(os.path.expanduser(config["path"]), encoding="utf-8") as handle:
        emit(config, handle.read(), f"source:file-json:{config['key']}")


if __name__ == "__main__":
    main()
