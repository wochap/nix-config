#!/usr/bin/env python3
"""Extract notes from class transcripts with omniroute-chat."""

import os
import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path
import tiktoken

# cl100k_base is the GPT-4/GPT-3.5 tokenizer.
# It is useful for estimating token usage in modern models.
encoding = tiktoken.get_encoding("cl100k_base")


def count_tokens(text: str) -> int:
    return len(encoding.encode(text))


# Timestamps such as [02:57.84].
TIMESTAMP_RE = re.compile(r"\[\d{2}:\d{2}\.\d{2}\]")


def clean_transcript(raw: str) -> str:
    """Remove timestamps from the transcript while preserving speaker labels."""
    text = re.sub(TIMESTAMP_RE.pattern + r"\s*", "", raw)

    # Collapse multiple consecutive blank lines.
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()


def load_prompt(prompt_path: Path) -> str:
    """Load the prompt from a file."""
    if not prompt_path.exists():
        print(
            f"Error: Prompt file not found: {prompt_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    return prompt_path.read_text(encoding="utf-8").strip()


DEFAULT_MODEL = "desktop-free"


def fail(message: str, stderr: str = "") -> None:
    print(f"Error: {message}", file=sys.stderr)
    if stderr:
        print(f"stderr: {stderr}", file=sys.stderr)
    sys.exit(1)


def run_command(cmd: list[str], stdin: str) -> str:
    try:
        result = subprocess.run(
            cmd, input=stdin, text=True, capture_output=True, check=True
        )
    except FileNotFoundError:
        fail(f"Command '{cmd[0]}' not found. Make sure it is available in your PATH.")
    except subprocess.CalledProcessError as e:
        fail(f"{cmd[0]} exited with {e.returncode}", e.stderr)
    return result.stdout


def chat_request(message: str, model: str, temperature: float) -> dict:
    """An OpenAI-compatible chat request."""
    return {
        "model": model,
        "messages": [{"role": "user", "content": message}],
        "stream": False,
        "temperature": temperature,
    }


def run_omniroute(message: str, model: str, temperature: float) -> str:
    return run_command(
        [
            "omniroute-chat",
            "--reasoning-effort",
            os.environ.get("OMNIROUTE_REASONING_EFFORT", "none"),
            "--stream",
        ],
        json.dumps(chat_request(message, model, temperature)),
    )


def main():
    parser = argparse.ArgumentParser(description="Extract notes from class transcripts")

    parser.add_argument(
        "transcript_file",
        type=Path,
        help="Path to the transcript file",
    )

    parser.add_argument(
        "--prompt-file",
        type=Path,
        default=Path(os.environ.get("DEFAULT_PROMPT", "prompt.md")),
        help="Path to the prompt file (default: DEFAULT_PROMPT or prompt.md)",
    )

    parser.add_argument(
        "--model",
        type=str,
        default=None,
        help="Model to use (default: COURSE_NOTES_MODEL or desktop-free)",
    )

    parser.add_argument(
        "--temperature",
        type=float,
        default=0.1,
        help="Generation temperature (default: 0.1)",
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate the notes even if the note file already exists",
    )

    parser.add_argument(
        "--require-timestamps",
        action="store_true",
        help="Skip the file (exit 0) unless it has [MM:SS.xx] timestamps",
    )

    args = parser.parse_args()

    # Validate the transcript file.
    if not args.transcript_file.exists():
        print(
            f"Error: File not found: {args.transcript_file}",
            file=sys.stderr,
        )
        sys.exit(1)

    # Generate the output path next to the transcript.
    # Example: lecture.txt -> lecture_note.md
    output_file = args.transcript_file.with_name(f"{args.transcript_file.stem}_note.md")
    if output_file.exists() and not args.force:
        print(
            f"Exists, skipping: {output_file} (use --force to regenerate)",
            file=sys.stderr,
        )
        sys.exit(0)

    # Load and clean the transcript.
    raw_transcript = args.transcript_file.read_text(encoding="utf-8")
    if args.require_timestamps and not TIMESTAMP_RE.search(raw_transcript):
        print(
            f"Skipped: no [MM:SS.xx] timestamps in {args.transcript_file}",
            file=sys.stderr,
        )
        sys.exit(0)
    cleaned = clean_transcript(raw_transcript)

    # Count transcript tokens.
    transcript_tokens = count_tokens(cleaned)
    print(
        f"Transcript tokens: {transcript_tokens}",
        file=sys.stderr,
    )

    # Load the prompt and count its tokens.
    prompt = load_prompt(args.prompt_file)
    prompt_tokens = count_tokens(prompt)
    print(
        f"Prompt tokens: {prompt_tokens}",
        file=sys.stderr,
    )

    total_tokens = transcript_tokens + prompt_tokens
    print(
        f"Total tokens (Input): {total_tokens}",
        file=sys.stderr,
    )

    # Warn if the input context is very long.
    if total_tokens > 14000:
        print(
            "⚠️ Warning: Long context (>14k). "
            "Possible truncation or 'lost in the middle' risk.",
            file=sys.stderr,
        )

    # Build the user message.
    user_message = f"{prompt}\n\n--- TRANSCRIPT ---\n{cleaned}"

    model = args.model or os.environ.get("COURSE_NOTES_MODEL") or DEFAULT_MODEL
    print(f"Model: {model}", file=sys.stderr)

    print("Generating notes...", file=sys.stderr)
    started = time.monotonic()
    notes = run_omniroute(user_message, model, args.temperature)

    elapsed = time.monotonic() - started
    print(
        f"Generated in {elapsed:.0f}s ({count_tokens(notes)} output tokens)",
        file=sys.stderr,
    )

    # Save the generated notes as a Markdown file.
    output_file.write_text(notes.strip() + "\n", encoding="utf-8")
    print(f"Notes saved to: {output_file}", file=sys.stderr)


if __name__ == "__main__":
    main()

