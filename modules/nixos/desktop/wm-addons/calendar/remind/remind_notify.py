"""Turn Remind's JSON daemon events into desktop notifications.

Usage: remind_notify.py REMIND_BIN NOTIFY_SEND_BIN REM_FILE
"""

import contextlib
import json
import signal
import subprocess
import sys
from datetime import date, datetime


REMIND_BIN, NOTIFY_SEND_BIN, REM_FILE = sys.argv[1:4]


def minutes_until(entry):
    event = datetime.fromisoformat(entry["tdatetime"])
    now_time = datetime.strptime(entry["now"], "%H:%M").time()
    now = datetime.combine(date.today(), now_time)
    return int((event - now).total_seconds() // 60)


def notify(entry):
    minutes = minutes_until(entry)
    args = [
        NOTIFY_SEND_BIN,
        "--app-name=remind",
        "--app-icon=kalarm",
        "--icon=kalarm",
        "--hint=string:custom-sound:message",
    ]

    if minutes > 0:
        title = f"Upcoming reminder (in {minutes} minutes)"
    else:
        args.append("--urgency=critical")
        title = "Reminder — starting now"

    subprocess.run([*args, title, entry.get("body") or "reminder"], check=False)


def main():
    proc = subprocess.Popen(
        [REMIND_BIN, "--flush", "-zj", REM_FILE],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    def reload_remind(_signum, _frame):
        with contextlib.suppress(ProcessLookupError):
            proc.send_signal(signal.SIGHUP)

    def stop_remind(_signum, _frame):
        with contextlib.suppress(ProcessLookupError):
            proc.terminate()

    signal.signal(signal.SIGHUP, reload_remind)
    signal.signal(signal.SIGTERM, stop_remind)

    assert proc.stdout is not None
    for line in proc.stdout:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError as error:
            print(f"remind-notify: invalid JSON: {error}: {line.rstrip()}", file=sys.stderr)
            continue

        if entry.get("response") == "reminder":
            try:
                notify(entry)
            except (KeyError, TypeError, ValueError) as error:
                print(f"remind-notify: invalid reminder: {error}: {entry!r}", file=sys.stderr)

    return proc.wait()


if __name__ == "__main__":
    sys.exit(main())
