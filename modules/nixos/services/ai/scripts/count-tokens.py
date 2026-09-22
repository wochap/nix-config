"""Print the number of tokens in a file, as counted by tiktoken.

Usage: count-tokens [--encoding NAME] FILE

The encoding defaults to o200k_base (GPT-4o family). Use --encoding to
pick another one, e.g. cl100k_base for GPT-4 / text-embedding-3.
"""

import argparse
import sys

import tiktoken


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="count-tokens",
        description="Count tokens in a file with tiktoken.",
    )
    parser.add_argument("file", help="path to the text file to count")
    parser.add_argument(
        "--encoding",
        default="o200k_base",
        help="tiktoken encoding name (default: o200k_base)",
    )
    args = parser.parse_args()

    try:
        with open(args.file, "r", encoding="utf-8", errors="replace") as handle:
            text = handle.read()
    except OSError as error:
        print(f"count-tokens: cannot read {args.file}: {error}", file=sys.stderr)
        return 1

    try:
        encoding = tiktoken.get_encoding(args.encoding)
    except ValueError as error:
        print(f"count-tokens: {error}", file=sys.stderr)
        return 1

    print(len(encoding.encode(text, disallowed_special=())))
    return 0


if __name__ == "__main__":
    sys.exit(main())
