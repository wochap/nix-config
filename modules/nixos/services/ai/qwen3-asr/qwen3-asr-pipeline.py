#!/usr/bin/env python3

import argparse
import gc
import json
import os
import re
import sys
import wave
from pathlib import Path
from typing import Any


LANGUAGE_ALIASES = {
    "ar": "Arabic",
    "cs": "Czech",
    "da": "Danish",
    "de": "German",
    "el": "Greek",
    "en": "English",
    "es": "Spanish",
    "fa": "Persian",
    "fi": "Finnish",
    "fil": "Filipino",
    "fr": "French",
    "hi": "Hindi",
    "hu": "Hungarian",
    "id": "Indonesian",
    "it": "Italian",
    "ja": "Japanese",
    "ko": "Korean",
    "mk": "Macedonian",
    "ms": "Malay",
    "nl": "Dutch",
    "pl": "Polish",
    "pt": "Portuguese",
    "ro": "Romanian",
    "ru": "Russian",
    "sv": "Swedish",
    "th": "Thai",
    "tr": "Turkish",
    "vi": "Vietnamese",
    "yue": "Cantonese",
    "zh": "Chinese",
}


def canonical_language(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    if not value:
        return None
    return LANGUAGE_ALIASES.get(value.casefold(), value.title())


def wav_duration(path: Path) -> float:
    with wave.open(str(path), "rb") as audio:
        return audio.getnframes() / audio.getframerate()


def load_pcm_wav(path: Path):
    """Load FFmpeg-produced mono PCM without exposing pyannote to torchcodec."""
    import numpy as np
    import torch

    with wave.open(str(path), "rb") as audio:
        if audio.getnchannels() != 1 or audio.getsampwidth() != 2:
            raise ValueError(f"expected mono 16-bit PCM WAV: {path}")
        sample_rate = audio.getframerate()
        samples = np.frombuffer(audio.readframes(audio.getnframes()), dtype="<i2")
    waveform = torch.from_numpy(samples.copy()).float().div_(32768.0).unsqueeze(0)
    return waveform, sample_rate


def release_cuda_memory() -> None:
    gc.collect()
    try:
        import torch

        torch.cuda.empty_cache()
    except (ImportError, RuntimeError):
        pass


def display_units(text: str, aligned_units: list[str]) -> list[str]:
    """Map normalized aligner units back onto the ASR text surface form."""
    if not aligned_units:
        return []

    starts: list[int] = []
    cursor = 0
    for unit in aligned_units:
        match = re.search(re.escape(unit), text[cursor:], flags=re.IGNORECASE)
        if match is None:
            return fallback_display_units(aligned_units)
        start = cursor + match.start()
        starts.append(start)
        cursor += match.end()

    result = []
    for index, start in enumerate(starts):
        if index == 0:
            start = 0
        end = starts[index + 1] if index + 1 < len(starts) else len(text)
        result.append(text[start:end])
    return result


def fallback_display_units(units: list[str]) -> list[str]:
    result = []
    for index, unit in enumerate(units):
        if index + 1 < len(units) and needs_space(unit, units[index + 1]):
            result.append(f"{unit} ")
        else:
            result.append(unit)
    return result


def needs_space(left: str, right: str) -> bool:
    cjk = re.compile(r"[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uac00-\ud7af]")
    return bool(
        not cjk.search(left[-1:])
        and not cjk.search(right[:1])
        and re.search(r"[\w]$", left, re.UNICODE)
        and re.match(r"^[\w]", right, re.UNICODE)
    )


MAX_SPEAKER_DISTANCE = 0.5


def point_region_distance(point: float, region: dict[str, Any]) -> float:
    if point < region["start"]:
        return region["start"] - point
    if point > region["end"]:
        return point - region["end"]
    return 0.0


def assign_speakers(
    tokens: list[dict[str, Any]],
    regions: list[dict[str, Any]],
    max_distance: float = MAX_SPEAKER_DISTANCE,
) -> None:
    for token in tokens:
        best_region = None
        best_overlap = 0.0
        for region in regions:
            overlap = max(
                0.0,
                min(token["end"], region["end"]) - max(token["start"], region["start"]),
            )
            if overlap > best_overlap:
                best_overlap = overlap
                best_region = region
        if best_region is None:
            midpoint = (token["start"] + token["end"]) / 2
            nearest = min(
                regions,
                key=lambda region: (
                    point_region_distance(midpoint, region),
                    region["start"] > midpoint,
                    region["start"],
                    region["end"],
                    region["speaker"],
                ),
                default=None,
            )
            if nearest is not None and point_region_distance(midpoint, nearest) <= max_distance:
                best_region = nearest
        token["speaker"] = best_region["speaker"] if best_region is not None else "UNKNOWN"


def token_distance(point: float, token: dict[str, Any]) -> float:
    if point < token["start"]:
        return token["start"] - point
    if point > token["end"]:
        return point - token["end"]
    return 0.0


def smooth_unknown_speakers(
    tokens: list[dict[str, Any]], max_distance: float = MAX_SPEAKER_DISTANCE
) -> None:
    index = 0
    while index < len(tokens):
        if tokens[index]["speaker"] != "UNKNOWN":
            index += 1
            continue

        start = index
        while index < len(tokens) and tokens[index]["speaker"] == "UNKNOWN":
            index += 1
        end = index
        previous = tokens[start - 1] if start > 0 else None
        following = tokens[end] if end < len(tokens) else None

        for token in tokens[start:end]:
            midpoint = (token["start"] + token["end"]) / 2
            candidates = []
            if previous is not None:
                candidates.append((token_distance(midpoint, previous), 0, previous["speaker"]))
            if following is not None:
                candidates.append((token_distance(midpoint, following), 1, following["speaker"]))
            if candidates:
                distance, _, speaker = min(candidates)
                if distance <= max_distance:
                    token["speaker"] = speaker


def build_turns(tokens: list[dict[str, Any]], gap_seconds: float = 1.0) -> list[dict[str, Any]]:
    turns: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None

    for token in tokens:
        should_split = (
            current is None
            or token["speaker"] != current["speaker"]
            or token["start"] - current["end"] > gap_seconds
        )
        if should_split:
            if current is not None:
                current["text"] = current.pop("_display").strip()
                turns.append(current)
            current = {
                "start": token["start"],
                "end": token["end"],
                "speaker": token["speaker"],
                "_display": token.get("display", token["text"]),
            }
        else:
            current["end"] = token["end"]
            current["_display"] += token.get("display", token["text"])

    if current is not None:
        current["text"] = current.pop("_display").strip()
        turns.append(current)
    return turns


def transcript_timestamp(seconds: float) -> str:
    centiseconds = max(0, int(round(seconds * 100)))
    hours, remainder = divmod(centiseconds, 360000)
    minutes, remainder = divmod(remainder, 6000)
    secs, fraction = divmod(remainder, 100)
    if hours:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}.{fraction:02d}"
    return f"{minutes:02d}:{secs:02d}.{fraction:02d}"


def infer(args: argparse.Namespace) -> None:
    import torch
    from pyannote.audio import Pipeline
    from qwen_asr import Qwen3ASRModel, Qwen3ForcedAligner

    audio_dir = Path(args.audio_dir)
    full_audio = audio_dir / "full.wav"
    chunks = sorted(audio_dir.glob("chunk-*.wav"))
    if not full_audio.is_file() or not chunks:
        raise RuntimeError("input directory must contain full.wav and chunk-*.wav")

    requested_language = canonical_language(args.language)
    chunk_records: list[dict[str, Any]] = []
    offset = 0.0

    # TODO: Make the accelerator and dtype configurable. cuda:0 and bfloat16
    # are tuned for the RTX 4060 and do not support AMD/ROCm or CPU-only hosts.
    print("Loading Qwen3-ASR-1.7B", file=sys.stderr)
    asr_model = Qwen3ASRModel.from_pretrained(
        "Qwen/Qwen3-ASR-1.7B",
        dtype=torch.bfloat16,
        device_map="cuda:0",
        max_inference_batch_size=1,
        max_new_tokens=4096,
    )
    for index, chunk in enumerate(chunks, start=1):
        duration = wav_duration(chunk)
        print(f"Transcribing chunk {index}/{len(chunks)}", file=sys.stderr)
        result = asr_model.transcribe(audio=str(chunk), language=requested_language)[0]
        chunk_records.append(
            {
                "start": round(offset, 3),
                "end": round(offset + duration, 3),
                "language": canonical_language(result.language) or requested_language,
                "text": result.text,
                "path": str(chunk),
            }
        )
        offset += duration
    del asr_model
    release_cuda_memory()

    print("Loading Qwen3-ForcedAligner-0.6B", file=sys.stderr)
    aligner = Qwen3ForcedAligner.from_pretrained(
        "Qwen/Qwen3-ForcedAligner-0.6B",
        dtype=torch.bfloat16,
        device_map="cuda:0",
    )
    aligned_tokens: list[dict[str, Any]] = []
    for index, chunk in enumerate(chunk_records, start=1):
        if not chunk["text"].strip():
            continue
        language = chunk["language"]
        if language is None:
            raise RuntimeError(f"Qwen did not detect a language for chunk {index}")
        print(f"Aligning chunk {index}/{len(chunk_records)}", file=sys.stderr)
        aligned = aligner.align(
            audio=chunk["path"],
            text=chunk["text"],
            language=language,
        )[0]
        surfaces = display_units(chunk["text"], [item.text for item in aligned])
        for item, display in zip(aligned, surfaces):
            aligned_tokens.append(
                {
                    "start": round(chunk["start"] + item.start_time, 3),
                    "end": round(chunk["start"] + item.end_time, 3),
                    "text": item.text,
                    "display": display,
                    "speaker": None,
                }
            )
    del aligner
    release_cuda_memory()

    print("Loading pyannote Community-1", file=sys.stderr)
    token = os.environ.get("HF_TOKEN")
    diarizer = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-community-1",
        token=token,
    )
    # TODO: Use the configurable accelerator here too so diarization supports
    # AMD/ROCm and CPU-only hosts instead of unconditionally requiring CUDA.
    diarizer.to(torch.device("cuda"))
    waveform, sample_rate = load_pcm_wav(full_audio)
    diarization_kwargs = {
        key: value
        for key, value in {
            "num_speakers": args.num_speakers,
            "min_speakers": args.min_speakers,
            "max_speakers": args.max_speakers,
        }.items()
        if value is not None
    }
    diarization_output = diarizer(
        {"waveform": waveform, "sample_rate": sample_rate},
        **diarization_kwargs,
    )
    annotation = diarization_output.exclusive_speaker_diarization
    regions = [
        {
            "start": round(turn.start, 3),
            "end": round(turn.end, 3),
            "speaker": speaker,
        }
        for turn, _, speaker in annotation.itertracks(yield_label=True)
    ]
    regions.sort(key=lambda item: (item["start"], item["end"], item["speaker"]))

    assign_speakers(aligned_tokens, regions)
    smooth_unknown_speakers(aligned_tokens)
    turns = build_turns(aligned_tokens)
    for chunk in chunk_records:
        del chunk["path"]

    document = {
        "schema_version": 1,
        "source": {"name": args.source_name, "duration": round(wav_duration(full_audio), 3)},
        "requested_language": requested_language,
        "detected_languages": list(
            dict.fromkeys(chunk["language"] for chunk in chunk_records if chunk["language"])
        ),
        "chunks": chunk_records,
        "tokens": aligned_tokens,
        "exclusive_diarization": regions,
        "turns": turns,
    }
    json.dump(document, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


def render(args: argparse.Namespace) -> None:
    with open(args.input, encoding="utf-8") as input_file:
        document = json.load(input_file)
    if document.get("schema_version") != 1:
        raise RuntimeError("unsupported qwen3-asr JSON schema")
    for turn in document["turns"]:
        print(f"[{transcript_timestamp(turn['start'])}] {turn['speaker']}: {turn['text']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    infer_parser = subparsers.add_parser("infer")
    infer_parser.add_argument("--audio-dir", required=True)
    infer_parser.add_argument("--source-name", required=True)
    infer_parser.add_argument("--language")
    infer_parser.add_argument("--num-speakers", type=int)
    infer_parser.add_argument("--min-speakers", type=int)
    infer_parser.add_argument("--max-speakers", type=int)
    infer_parser.set_defaults(func=infer)

    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("--input", required=True)
    render_parser.set_defaults(func=render)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
