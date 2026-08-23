#!/usr/bin/env python3

import argparse
import array
import gc
import json
import math
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

ASR_REVISION = os.environ.get("QWEN3_ASR_ASR_REVISION", "")
ALIGNER_REVISION = os.environ.get("QWEN3_ASR_ALIGNER_REVISION", "")
DIARIZER_REVISION = os.environ.get("QWEN3_ASR_DIARIZER_REVISION", "")


def write_json_atomic(path: Path, value: Any) -> None:
    temporary = path.with_suffix(f"{path.suffix}.tmp")
    with open(temporary, "w", encoding="utf-8") as output:
        json.dump(value, output, ensure_ascii=False, indent=2)
        output.write("\n")
    os.replace(temporary, path)


def read_json(path: Path, default: Any) -> Any:
    try:
        with open(path, encoding="utf-8") as input_file:
            return json.load(input_file)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return default


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


def silence_midpoints(
    path: Path, silence_db: float = -35.0, min_silence_seconds: float = 0.4
) -> list[float]:
    """Return midpoints of sufficiently long quiet regions in mono PCM audio."""
    threshold = 32768.0 * 10 ** (silence_db / 20.0)
    result: list[float] = []
    if min_silence_seconds <= 0:
        raise ValueError("minimum silence duration must be positive")
    with wave.open(str(path), "rb") as audio:
        if audio.getnchannels() != 1 or audio.getsampwidth() != 2:
            raise ValueError(f"expected mono 16-bit PCM WAV: {path}")
        sample_rate = audio.getframerate()
        block_frames = max(1, round(sample_rate * 0.02))
        quiet_start: float | None = None
        position = 0
        end = 0.0
        while samples_bytes := audio.readframes(block_frames):
            samples = array.array("h")
            samples.frombytes(samples_bytes)
            if sys.byteorder != "little":
                samples.byteswap()
            rms = math.sqrt(sum(sample * sample for sample in samples) / len(samples))
            start = position / sample_rate
            position += len(samples)
            end = position / sample_rate
            if rms <= threshold:
                if quiet_start is None:
                    quiet_start = start
            elif quiet_start is not None:
                if start - quiet_start >= min_silence_seconds:
                    result.append((quiet_start + start) / 2.0)
                quiet_start = None
        if quiet_start is not None and end - quiet_start >= min_silence_seconds:
            result.append((quiet_start + end) / 2.0)
    return result


def plan_chunk_boundaries(
    duration: float,
    silences: list[float],
    max_seconds: float = 240.0,
    search_seconds: float = 30.0,
) -> list[float]:
    """Choose silence boundaries without ever exceeding max_seconds."""
    if max_seconds <= 0 or search_seconds < 0:
        raise ValueError("chunk durations must be positive")
    minimum_tail = min(30.0, max_seconds / 4.0)
    boundaries: list[float] = []
    start = 0.0
    while duration - start > max_seconds:
        latest = min(start + max_seconds, duration - minimum_tail)
        earliest = max(start + minimum_tail, latest - search_seconds)
        candidates = [point for point in silences if earliest <= point <= latest]
        boundary = max(candidates, default=latest)
        boundaries.append(round(boundary, 3))
        start = boundary
    return boundaries


def plan_chunks(args: argparse.Namespace) -> None:
    path = Path(args.input)
    duration = wav_duration(path)
    silences = silence_midpoints(path, args.silence_db, args.min_silence_seconds)
    effective_max = args.max_seconds - args.muxer_margin_seconds
    if effective_max <= 0:
        raise ValueError("muxer margin must be smaller than maximum chunk duration")
    boundaries = plan_chunk_boundaries(
        duration, silences, effective_max, args.search_seconds
    )
    print(",".join(str(boundary) for boundary in boundaries))


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

    if not all((ASR_REVISION, ALIGNER_REVISION, DIARIZER_REVISION)):
        raise RuntimeError("model revision environment variables are required")

    audio_dir = Path(args.audio_dir)
    full_audio = audio_dir / "full.wav"
    chunks = sorted(audio_dir.glob("chunk-*.wav"))
    if not full_audio.is_file() or not chunks:
        raise RuntimeError("input directory must contain full.wav and chunk-*.wav")

    requested_language = canonical_language(args.language)
    state_dir = Path(args.state_dir)
    state_dir.mkdir(parents=True, exist_ok=True)
    durations = [wav_duration(chunk) for chunk in chunks]
    signature = {
        "schema_version": 1,
        "source_name": args.source_name,
        "source_id": args.source_id,
        "durations": [round(duration, 3) for duration in durations],
        "language": requested_language,
        "num_speakers": args.num_speakers,
        "min_speakers": args.min_speakers,
        "max_speakers": args.max_speakers,
        "revisions": [ASR_REVISION, ALIGNER_REVISION, DIARIZER_REVISION],
    }
    signature_path = state_dir / "signature.json"
    if read_json(signature_path, None) != signature:
        for name in ("asr.json", "alignment.json", "diarization.json"):
            (state_dir / name).unlink(missing_ok=True)
        write_json_atomic(signature_path, signature)

    asr_path = state_dir / "asr.json"
    chunk_records: list[dict[str, Any]] = read_json(asr_path, [])
    if len(chunk_records) > len(chunks):
        chunk_records = []

    # TODO: Make the accelerator and dtype configurable. cuda:0 and bfloat16
    # are tuned for the RTX 4060 and do not support AMD/ROCm or CPU-only hosts.
    if len(chunk_records) < len(chunks):
        print("Loading Qwen3-ASR-1.7B", file=sys.stderr)
        asr_model = Qwen3ASRModel.from_pretrained(
            "Qwen/Qwen3-ASR-1.7B",
            revision=ASR_REVISION,
            dtype=torch.bfloat16,
            device_map="cuda:0",
            max_inference_batch_size=1,
            max_new_tokens=4096,
        )
    else:
        asr_model = None
        print(f"Reusing all {len(chunks)} ASR chunks", file=sys.stderr)
    offset = sum(durations[: len(chunk_records)])
    for index, chunk in enumerate(chunks[len(chunk_records) :], start=len(chunk_records) + 1):
        duration = durations[index - 1]
        print(f"Transcribing chunk {index}/{len(chunks)}", file=sys.stderr)
        assert asr_model is not None
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
        write_json_atomic(asr_path, chunk_records)
    del asr_model
    release_cuda_memory()

    alignment_path = state_dir / "alignment.json"
    aligned_chunks: list[list[dict[str, Any]]] = read_json(alignment_path, [])
    if len(aligned_chunks) > len(chunk_records):
        aligned_chunks = []
    if len(aligned_chunks) < len(chunk_records):
        print("Loading Qwen3-ForcedAligner-0.6B", file=sys.stderr)
        aligner = Qwen3ForcedAligner.from_pretrained(
            "Qwen/Qwen3-ForcedAligner-0.6B",
            revision=ALIGNER_REVISION,
            dtype=torch.bfloat16,
            device_map="cuda:0",
        )
    else:
        aligner = None
        print(f"Reusing all {len(chunk_records)} aligned chunks", file=sys.stderr)
    for index, chunk in enumerate(
        chunk_records[len(aligned_chunks) :], start=len(aligned_chunks) + 1
    ):
        chunk_tokens: list[dict[str, Any]] = []
        if not chunk["text"].strip():
            aligned_chunks.append(chunk_tokens)
            write_json_atomic(alignment_path, aligned_chunks)
            continue
        language = chunk["language"]
        if language is None:
            raise RuntimeError(f"Qwen did not detect a language for chunk {index}")
        print(f"Aligning chunk {index}/{len(chunk_records)}", file=sys.stderr)
        assert aligner is not None
        aligned = aligner.align(
            audio=chunk["path"],
            text=chunk["text"],
            language=language,
        )[0]
        surfaces = display_units(chunk["text"], [item.text for item in aligned])
        for item, display in zip(aligned, surfaces):
            chunk_tokens.append(
                {
                    "start": round(chunk["start"] + item.start_time, 3),
                    "end": round(chunk["start"] + item.end_time, 3),
                    "text": item.text,
                    "display": display,
                    "speaker": None,
                }
            )
        aligned_chunks.append(chunk_tokens)
        write_json_atomic(alignment_path, aligned_chunks)
    aligned_tokens = [token for chunk_tokens in aligned_chunks for token in chunk_tokens]
    del aligner
    release_cuda_memory()

    diarization_path = state_dir / "diarization.json"
    regions = read_json(diarization_path, None)
    if regions is None:
        print("Loading pyannote Community-1", file=sys.stderr)
        token = os.environ.get("HF_TOKEN")
        diarizer = Pipeline.from_pretrained(
            "pyannote/speaker-diarization-community-1",
            revision=DIARIZER_REVISION,
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
        write_json_atomic(diarization_path, regions)
    else:
        print("Reusing speaker diarization", file=sys.stderr)

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


def validate(args: argparse.Namespace) -> None:
    with open(args.input, encoding="utf-8") as input_file:
        document = json.load(input_file)
    errors = []
    if document.get("schema_version") != 1:
        errors.append("unsupported schema_version")
    duration = document.get("source", {}).get("duration")
    if not isinstance(duration, (int, float)) or not math.isfinite(duration) or duration <= 0:
        errors.append("source duration must be finite and positive")
    for key in ("chunks", "tokens", "exclusive_diarization", "turns"):
        if not isinstance(document.get(key), list):
            errors.append(f"{key} must be a list")
    for collection in ("chunks", "tokens", "exclusive_diarization", "turns"):
        for index, item in enumerate(document.get(collection, [])):
            for key in ("start", "end"):
                value = item.get(key)
                if not isinstance(value, (int, float)) or not math.isfinite(value):
                    errors.append(f"{collection}[{index}].{key} is not finite")
            if (
                isinstance(item.get("start"), (int, float))
                and isinstance(item.get("end"), (int, float))
                and item["end"] < item["start"]
            ):
                errors.append(f"{collection}[{index}] ends before it starts")
    if errors:
        raise RuntimeError("invalid inference result: " + "; ".join(errors))

    tokens = document["tokens"]
    regions = document["exclusive_diarization"]
    empty_chunks = sum(not chunk.get("text", "").strip() for chunk in document["chunks"])
    unknown_tokens = sum(token.get("speaker") == "UNKNOWN" for token in tokens)
    short_regions = sum(region["end"] - region["start"] < 0.1 for region in regions)
    speakers = sorted({region.get("speaker") for region in regions if region.get("speaker")})
    print(
        "Quality report: "
        f"{len(document['chunks'])} chunks ({empty_chunks} empty), "
        f"{len(tokens)} tokens ({unknown_tokens} UNKNOWN), "
        f"{len(regions)} speaker regions ({short_regions} under 100 ms), "
        f"{len(speakers)} speakers",
        file=sys.stderr,
    )


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

    plan_parser = subparsers.add_parser("plan-chunks")
    plan_parser.add_argument("--input", required=True)
    plan_parser.add_argument("--max-seconds", type=float, required=True)
    plan_parser.add_argument("--search-seconds", type=float, default=30.0)
    plan_parser.add_argument("--muxer-margin-seconds", type=float, default=0.25)
    plan_parser.add_argument("--min-silence-seconds", type=float, default=0.4)
    plan_parser.add_argument("--silence-db", type=float, default=-35.0)
    plan_parser.set_defaults(func=plan_chunks)

    infer_parser = subparsers.add_parser("infer")
    infer_parser.add_argument("--audio-dir", required=True)
    infer_parser.add_argument("--state-dir", required=True)
    infer_parser.add_argument("--source-name", required=True)
    infer_parser.add_argument("--source-id", required=True)
    infer_parser.add_argument("--language")
    infer_parser.add_argument("--num-speakers", type=int)
    infer_parser.add_argument("--min-speakers", type=int)
    infer_parser.add_argument("--max-speakers", type=int)
    infer_parser.set_defaults(func=infer)

    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("--input", required=True)
    render_parser.set_defaults(func=render)

    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("--input", required=True)
    validate_parser.set_defaults(func=validate)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
