"""Stage collect: run every registered source adapter for this mode.

usage: briefing-collect --registry sources.json --mode daily|weekly --out DIR

Each registry entry {adapter, kind, modes, ...} is piped as JSON to the
executable `briefing-source-<adapter>` found on PATH, so new adapters can live
anywhere. Writes DIR/items.jsonl, DIR/facts.json and DIR/collect-report.json.
A failing source is reported, not fatal.
"""

import argparse
import json
import os
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor

from briefing.common import die, log, validate_item, write_json, write_jsonl

STAGE = "collect"


def run_source(key, entry, mode):
    adapter = entry["adapter"]
    executable = shutil.which(f"briefing-source-{adapter}")
    if not executable:
        return key, entry, None, f"no executable briefing-source-{adapter} on PATH"
    config = {**entry, "key": key, "mode": mode}
    started = time.monotonic()
    try:
        result = subprocess.run(
            [executable], input=json.dumps(config), capture_output=True, text=True, timeout=int(entry.get("timeout", 600)), check=False
        )
    except subprocess.TimeoutExpired:
        return key, entry, None, "timed out"
    for line in result.stderr.splitlines():
        log(STAGE, line)
    if result.returncode != 0:
        tail = result.stderr.strip().splitlines()
        return key, entry, None, f"exit {result.returncode}: {tail[-1] if tail else ''}"
    log(STAGE, f"{key}: done in {time.monotonic() - started:.1f}s")
    return key, entry, result.stdout, None


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--registry", required=True)
    parser.add_argument("--mode", default="daily")
    parser.add_argument("--out", required=True)
    parser.add_argument("--only", action="append", help="run only these source keys")
    args = parser.parse_args()

    with open(args.registry, encoding="utf-8") as handle:
        registry = json.load(handle)
    selected = {
        key: entry
        for key, entry in registry.items()
        if entry.get("enable", True) and args.mode in entry.get("modes", ["daily", "weekly"]) and (not args.only or key in args.only)
    }
    if not selected:
        die(STAGE, f"no sources enabled for mode {args.mode}")

    with ThreadPoolExecutor(max_workers=len(selected)) as pool:
        results = list(pool.map(lambda kv: run_source(kv[0], kv[1], args.mode), selected.items()))

    items, facts, report = {}, [], {}
    for key, entry, stdout, error in results:
        if error:
            log(STAGE, f"{key}: FAILED {error}")
            report[key] = {"ok": False, "error": error}
            continue
        try:
            if entry.get("kind", "items") == "facts":
                data = json.loads(stdout)
                data["source"] = key
                facts.append(data)
                report[key] = {"ok": True, "facts": len(data.get("highlights", []))}
            else:
                count = 0
                for line in stdout.splitlines():
                    if not line.strip():
                        continue
                    item = json.loads(line)
                    item["source"] = key
                    validate_item(item)
                    count += 1
                    if item["id"] in items:
                        # Same URL from two feeds: keep one, remember both feeds.
                        kept = items[item["id"]]
                        kept.setdefault("also_in", []).append(item["feed"])
                        continue
                    items[item["id"]] = item
                report[key] = {"ok": True, "items": count}
        except (ValueError, KeyError) as error:
            log(STAGE, f"{key}: bad output: {error}")
            report[key] = {"ok": False, "error": f"bad output: {error}"}

    os.makedirs(args.out, exist_ok=True)
    write_jsonl(os.path.join(args.out, "items.jsonl"), items.values())
    write_json(os.path.join(args.out, "facts.json"), facts)
    write_json(os.path.join(args.out, "collect-report.json"), report)
    log(STAGE, f"{len(items)} unique items, {len(facts)} fact sets, {sum(not r['ok'] for r in report.values())} failed sources")
    if not items and not facts:
        die(STAGE, "every source failed or returned nothing")


if __name__ == "__main__":
    main()
