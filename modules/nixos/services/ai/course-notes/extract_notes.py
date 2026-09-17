#!/usr/bin/env python3
"""Extract notes from class transcripts using omniroute-chat."""

import os
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
import tiktoken

# cl100k_base is the GPT-4/GPT-3.5 tokenizer.
# It is useful for estimating token usage in modern models.
encoding = tiktoken.get_encoding("cl100k_base")


def count_tokens(text: str) -> int:
    return len(encoding.encode(text))


def clean_transcript(raw: str) -> str:
    """Remove timestamps from the transcript while preserving speaker labels."""
    # Remove timestamps such as [02:57.84].
    text = re.sub(r"\[\d{2}:\d{2}\.\d{2}\]\s*", "", raw)

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
        help="Model to use (overrides OMNIROUTE_MODEL)",
    )

    parser.add_argument(
        "--temperature",
        type=float,
        default=0.1,
        help="Generation temperature (default: 0.1)",
    )

    args = parser.parse_args()

    # Validate the transcript file.
    if not args.transcript_file.exists():
        print(
            f"Error: File not found: {args.transcript_file}",
            file=sys.stderr,
        )
        sys.exit(1)

    # Load and clean the transcript.
    raw_transcript = args.transcript_file.read_text(encoding="utf-8")
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

    # Build the OpenAI-compatible request.
    request = {
        "model": args.model if args.model else "desktop-free",
        "messages": [
            {
                "role": "user",
                "content": user_message,
            }
        ],
        "stream": False,
        "temperature": args.temperature,
    }

    # Generate the output path next to the transcript.
    # Example: lecture.txt -> lecture_note.md
    output_file = args.transcript_file.with_name(f"{args.transcript_file.stem}_note.md")

    # Call omniroute-chat.
    try:
        result = subprocess.run(
            ["omniroute-chat"],
            input=json.dumps(request),
            text=True,
            capture_output=True,
            check=True,
        )

        # Save the generated notes as a Markdown file.
        output_file.write_text(
            result.stdout.strip() + "\n",
            encoding="utf-8",
        )

        print(
            f"Notes saved to: {output_file}",
            file=sys.stderr,
        )

    except subprocess.CalledProcessError as e:
        print(
            f"Error running omniroute-chat: {e}",
            file=sys.stderr,
        )

        if e.stderr:
            print(
                f"stderr: {e.stderr}",
                file=sys.stderr,
            )

        sys.exit(1)

    except FileNotFoundError:
        print(
            "Error: Command 'omniroute-chat' not found.",
            file=sys.stderr,
        )
        print(
            "Make sure it is available in your PATH.",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()

