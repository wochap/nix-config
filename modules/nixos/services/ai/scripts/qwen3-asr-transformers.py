#!/usr/bin/env python3

import argparse
import sys

import torch
from qwen_asr import Qwen3ASRModel


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("audio", nargs="+")
    parser.add_argument("--language")
    args = parser.parse_args()

    model = Qwen3ASRModel.from_pretrained(
        "Qwen/Qwen3-ASR-1.7B",
        dtype=torch.bfloat16,
        device_map="cuda:0",
        max_inference_batch_size=1,
        max_new_tokens=4096,
    )
    for index, audio in enumerate(args.audio, start=1):
        if len(args.audio) > 1:
            print(f"Transcribing chunk {index}/{len(args.audio)}", file=sys.stderr)
        result = model.transcribe(audio=audio, language=args.language)[0]
        print(result.text, flush=True)


if __name__ == "__main__":
    main()
