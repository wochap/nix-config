"""Notify reminders that triggered while the remind daemon could not run
(machine suspended or powered off).

The state file stores the epoch of the last successful check. When the
gap since then exceeds a threshold, remind is asked for all triggers
inside the gap window and each missed one is notified once.

Usage: remind_catchup.py REMIND_BIN NOTIFY_SEND_BIN REM_FILE STATE_FILE
"""

import json
import os
import subprocess
import sys
from datetime import datetime

REMIND_BIN, NOTIFY_SEND_BIN, REM_FILE, STATE_FILE = sys.argv[1:5]
# Ignore ordinary timer jitter.
GAP_THRESHOLD_S = 5 * 60
MAX_LOOKBACK_DAYS = 7


def read_state():
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return float(f.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def write_state(ts):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        f.write(f"{ts:.0f}")


def main():
    now = datetime.now().astimezone()
    tz = now.tzinfo
    now_ts = now.timestamp()
    last_ts = read_state()

    if last_ts is None:
        write_state(now_ts)
        print("remind-catchup: first run, initialized state")
        return 0

    gap_s = now_ts - last_ts
    if gap_s < GAP_THRESHOLD_S:
        write_state(now_ts)
        return 0

    start = datetime.fromtimestamp(max(last_ts, now_ts - MAX_LOOKBACK_DAYS * 86400), tz)
    proc = subprocess.run(
        # Two months covers windows crossing a month boundary.
        [REMIND_BIN, "-ppp2", "-b2", REM_FILE, start.strftime("%Y-%m-%d")],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        # Preserve state so the window is retried.
        print(f"remind-catchup: remind failed: {proc.stderr.strip()}", file=sys.stderr)
        return 1

    notified = 0
    for month in json.loads(proc.stdout or "[]"):
        for entry in month.get("entries", []):
            if entry.get("eventstart"):
                # Missed pre-alerts must not be replayed after resume.
                trigger = datetime.strptime(entry["eventstart"], "%Y-%m-%dT%H:%M").replace(
                    tzinfo=tz
                )
            else:  # all-day event: triggers at local midnight
                trigger = datetime.strptime(entry["date"], "%Y-%m-%d").replace(tzinfo=tz)
            if last_ts < trigger.timestamp() <= now_ts:
                body = entry.get("body") or entry.get("rawbody") or "reminder"
                subprocess.run(
                    [
                        NOTIFY_SEND_BIN,
                        "--app-name=Remind",
                        "--app-icon=kalarm",
                        "--icon=kalarm",
                        "--hint=string:custom-sound:message",
                        "Missed reminder",
                        body,
                    ],
                    check=False,
                )
                notified += 1

    write_state(now_ts)
    print(f"remind-catchup: gap={gap_s:.0f}s notified={notified}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
