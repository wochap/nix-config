#!/usr/bin/env cached-nix-shell
#! nix-shell -i python3 -p "python3.withPackages(ps: with ps; [ pytz dateutil ])"

import os
import pathlib
import re
import sys
from datetime import datetime
from functools import lru_cache

import pytz
from dateutil import parser


class bcolors:
    BLUE = "\x1B[34m"
    GREEN = "\x1B[32m"
    YELLOW = "\x1B[33m"
    RED = "\x1B[31m"
    ENDC = "\033[0m"
    BOLD = "\x1B[1m"


@lru_cache(maxsize=None)
def create_url_verify_page(url):
    tmp_dir = pathlib.Path(os.path.expanduser("~/tmp/mdf/"))
    tmp_dir.mkdir(parents=True, exist_ok=True)
    if len(os.listdir(tmp_dir)) == 0:
        next_num = 1
    else:
        next_num = max(int(x, 16) for x in os.listdir(tmp_dir)) + 1

    filename = os.path.expanduser(f"~/tmp/mdf/{hex(next_num)}")

    with open(filename, "w+") as f:
        f.write(
            f"""
            <!doctype html>
            <html>
            <body>
                <textarea id="url_edit"
                          rows="10"
                          style="width: 100%;">{url}</textarea>
                <br />
                <input id="go" type="button" value="Go" />
                <script>
                    const redirect = () => {{
                        const url = document.getElementById('url_edit').value;
                        window.location.replace(url);
                    }}
                    document.getElementById('go').addEventListener('click', redirect);
                    document.onkeypress = e => {{
                        if (e.keyCode === 13) {{
                            redirect();
                            return false;
                        }}
                    }};
                    document.getElementById('url_edit').focus();
                </script>
            </body>
            </html>
            """
        )

    return f"<file://{filename}>"


def parse_datetime(datetime_string):
    # https://docs.python.org/3/library/datetime.html#strftime-and-strptime-behavior
    alternative_formats = []
    try:
        return parser.parse(datetime_string, fuzzy_with_tokens=True)[0]
    except ValueError:
        for f in alternative_formats:
            try:
                return datetime.strptime(datetime_string, f)
            except ValueError:
                pass


# Git diff state
hit_diff = False
hit_diff_footer = False
git_summary_file_re = re.compile(r" .* \| +\d+ [\+-]")
git_summary_re = re.compile(
    r" (\d+) (files?) changed(?:, (\d+) (insertions?)\(\+\))(?:, (\d+) (deletions?)\(-\))"
)
diff_re = re.compile("diff --git")
diff_desc_re = re.compile(r"@@ (-\d+,\d+ \+\d+,\d+) @@")

date_re = re.compile("Date: (.*)")
email_re = re.compile("<mailto:(.*?)>")
url_re = re.compile(r"(https?://[^\s]*)")


for line in sys.stdin.readlines():
    # Git handling
    if diff_re.match(line):
        hit_diff = True
        line = f"{bcolors.BOLD}{line}{bcolors.ENDC}"

    elif match := git_summary_re.match(line):
        line = f" {bcolors.BOLD}{match.group(1)} {match.group(2)} changed"
        if match.group(3) and match.group(4):
            line += f", {bcolors.GREEN}{match.group(3)} {match.group(4)}(+)"
        if match.group(5) and match.group(6):
            line += f", {bcolors.RED}{match.group(5)} {match.group(6)}(-){bcolors.ENDC}"
        line += "\n"

    elif git_summary_file_re.match(line):
        parts = line.split(" ")
        adds, removes = parts[-1].count("+"), parts[-1].count("-")
        parts[-2] = f"{bcolors.BOLD}{parts[-2]}{bcolors.ENDC}"
        parts[-1] = (
            f"{bcolors.GREEN}{'+' * adds}{bcolors.ENDC}"
            + f"{bcolors.RED}{'-' * removes}{bcolors.ENDC}"
        )
        line = " ".join(parts) + "\n"

    elif hit_diff_footer:
        line = f"{bcolors.YELLOW}{line}{bcolors.ENDC}"

    elif hit_diff:
        if line.startswith("--") and not line.startswith("---"):
            hit_diff_footer = True
            line = f"{bcolors.YELLOW}{line}{bcolors.ENDC}"
        elif line.startswith("-"):
            line = f"{bcolors.RED}{line}{bcolors.ENDC}"
        elif line.startswith("+"):
            line = f"{bcolors.GREEN}{line}{bcolors.ENDC}"
        elif diff_desc_re.match(line):
            line = f"{bcolors.BLUE}{line}{bcolors.ENDC}"
        elif line.startswith(" "):
            pass
        else:
            line = f"{bcolors.BOLD}{line}{bcolors.ENDC}"

    else:
        date_match = date_re.match(line)
        if date_match:
            # Fix Date to be in the local time
            date_str = date_match.groups()[0]
            dt = parse_datetime(date_str)
            if not dt:
                print("Date Parse Fail")
            else:
                tz_name = "/".join(os.readlink("/etc/localtime").split("/")[-2:])
                dt = dt.astimezone(pytz.timezone(tz_name))
                line = "Date: {}\n".format(dt.strftime("%a, %b %d %H:%M:%S %Y (%Z)"))
        elif email_re.findall(line):
            # Remove redundant <mailto:{email}>.
            for email in email_re.findall(line):
                if f"{email}<mailto:{email}>" in line:
                    line = line.replace(f"<mailto:{email}>", "")
        elif url_re.findall(line):
            # Create a HTML page that has a link to the actual URL, and give a
            # local address instead of a long URL.
            for url in url_re.findall(line):
                if len(url) > 30:
                    url_verify_page_filename = create_url_verify_page(url)
                    if len(url_verify_page_filename) < len(url):
                        line = line.replace(url, url_verify_page_filename)

    print(line, end="")
