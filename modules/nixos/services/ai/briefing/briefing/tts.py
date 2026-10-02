"""Stage tts: synthesize each chapter with the Supertonic HTTP API.

usage: briefing-tts --chapters chapters.json --out DIR [--voice M1] [--speed 1.0] [--steps 5]

Writes DIR/NN-<key>.wav per chapter. Long chapters are sent paragraph by
paragraph (<= ~1500 characters per request) and joined with ffmpeg.
Env: SUPERTONIC_URL (default https://supertonic.wochap.local).
"""

import argparse
import json
import os
import re
import subprocess
import tempfile
import urllib.request

from briefing.common import log, read_json

STAGE = "tts"
MAX_CHARS = 1500


def clean(text):
    text = re.sub(r"[*_#`>\[\]]", "", text)
    text = re.sub(r"https?://\S+", "", text)
    text = re.sub(r"[\U0001F000-\U0001FAFF☀-➿￼]", "", text)
    return re.sub(r"[ \t]+", " ", text).strip()


def pieces(text):
    chunk = ""
    for paragraph in [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]:
        if chunk and len(chunk) + len(paragraph) > MAX_CHARS:
            yield chunk
            chunk = ""
        if len(paragraph) > MAX_CHARS:
            for sentence in re.split(r"(?<=[.!?])\s+", paragraph):
                if chunk and len(chunk) + len(sentence) > MAX_CHARS:
                    yield chunk
                    chunk = ""
                chunk = f"{chunk} {sentence}".strip()
        else:
            chunk = f"{chunk}\n\n{paragraph}".strip()
    if chunk:
        yield chunk


def synthesize(url, text, voice, speed, steps, output):
    body = json.dumps(
        {"text": text, "voice": voice, "steps": steps, "speed": speed, "max_chunk_length": 400, "silence_duration": 0.2, "response_format": "wav", "lang": "en"}
    ).encode()
    request = urllib.request.Request(f"{url}/v1/tts", data=body, headers={"content-type": "application/json"})
    with urllib.request.urlopen(request, timeout=600) as response, open(output, "wb") as handle:
        handle.write(response.read())


def concat(parts, output):
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as listing:
        for part in parts:
            listing.write(f"file '{os.path.abspath(part)}'\n")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", listing.name, "-c", "copy", output], check=True)
    os.unlink(listing.name)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--chapters", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--voice", default=os.environ.get("BRIEFING_VOICE", "M1"))
    parser.add_argument("--speed", type=float, default=float(os.environ.get("BRIEFING_SPEED", "1.0")))
    parser.add_argument("--steps", type=int, default=int(os.environ.get("BRIEFING_STEPS", "8")))
    args = parser.parse_args()
    url = os.environ.get("SUPERTONIC_URL", "https://supertonic.wochap.local").rstrip("/")

    os.makedirs(args.out, exist_ok=True)
    for index, chapter in enumerate(read_json(args.chapters), start=1):
        output = os.path.join(args.out, f"{index:02d}-{chapter['key']}.wav")
        if os.path.exists(output):
            continue
        parts = []
        for number, text in enumerate(pieces(clean(chapter["text"]))):
            part = os.path.join(args.out, f".{index:02d}-{number:03d}.wav")
            synthesize(url, text, args.voice, args.speed, args.steps, part)
            parts.append(part)
        concat(parts, output)
        for part in parts:
            os.unlink(part)
        log(STAGE, f"{chapter['title']}: {len(parts)} requests")


if __name__ == "__main__":
    main()
