"""Generic adapter: run a shell command that prints JSON.

Config: {key, kind="items"|"facts", command="my-scraper --json", jq?, timeout=300}
"""

import json
import subprocess
import sys

from briefing.adapters.generic import emit


def main():
    config = json.load(sys.stdin)
    result = subprocess.run(["bash", "-c", config["command"]], capture_output=True, text=True, timeout=config.get("timeout", 300), check=True)
    emit(config, result.stdout, f"source:command:{config['key']}")


if __name__ == "__main__":
    main()
