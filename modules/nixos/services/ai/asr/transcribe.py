#!/usr/bin/env python3

import argparse
import importlib.util
import os
import sys


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("audio", nargs="+")
    parser.add_argument("--language")
    args = parser.parse_args()

    spec = importlib.util.spec_from_file_location("asr_adapter", "/opt/asr/adapter.py")
    adapter = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(adapter)
    transcriber = adapter.load_transcriber(
        os.environ.get("ASR_DEVICE") or "cuda:0", os.environ.get("ASR_DTYPE") or "bfloat16", 1
    )
    for index, audio in enumerate(args.audio, start=1):
        if len(args.audio) > 1:
            print(f"Transcribing chunk {index}/{len(args.audio)}", file=sys.stderr)
        print(transcriber.transcribe([audio], args.language)[0].text, flush=True)


if __name__ == "__main__":
    main()
