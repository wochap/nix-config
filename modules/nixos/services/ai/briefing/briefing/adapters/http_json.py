"""Generic adapter: GET a JSON endpoint.

Config: {key, kind="items"|"facts", url, params?, headers?, jq?}
"""

import json
import sys

from briefing.adapters.generic import emit
from briefing.common import http_get


def main():
    config = json.load(sys.stdin)
    raw = http_get(config["url"], params=config.get("params"), headers=config.get("headers"), timeout=60).decode("utf-8")
    emit(config, raw, f"source:http-json:{config['key']}")


if __name__ == "__main__":
    main()
