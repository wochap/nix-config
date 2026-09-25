"""Qwen3-ASR adapter: Qwen3-ASR-1.7B plus Qwen3-ForcedAligner-0.6B."""

import os
from dataclasses import dataclass


@dataclass
class Transcript:
    text: str
    language: str | None


@dataclass
class Unit:
    text: str
    start: float
    end: float


class Transcriber:
    def __init__(self, device: str, dtype: str, batch_size: int) -> None:
        import torch
        from qwen_asr import Qwen3ASRModel

        self.model = Qwen3ASRModel.from_pretrained(
            "Qwen/Qwen3-ASR-1.7B",
            revision=os.environ["ASR_REVISION_ASR"],
            dtype=getattr(torch, dtype),
            device_map=device,
            max_inference_batch_size=batch_size,
            max_new_tokens=4096,
        )

    def transcribe(self, paths: list[str], language: str | None) -> list[Transcript]:
        results = self.model.transcribe(audio=paths, language=language)
        return [Transcript(result.text, result.language) for result in results]


class Aligner:
    def __init__(self, device: str, dtype: str) -> None:
        import torch
        from qwen_asr import Qwen3ForcedAligner

        self.model = Qwen3ForcedAligner.from_pretrained(
            "Qwen/Qwen3-ForcedAligner-0.6B",
            revision=os.environ["ASR_REVISION_ALIGNER"],
            dtype=getattr(torch, dtype),
            device_map=device,
        )

    def align(self, path: str, text: str, language: str) -> list[Unit]:
        aligned = self.model.align(audio=path, text=text, language=language)[0]
        return [Unit(item.text, item.start_time, item.end_time) for item in aligned]


def load_transcriber(device: str, dtype: str, batch_size: int) -> Transcriber:
    return Transcriber(device, dtype, batch_size)


def load_aligner(device: str, dtype: str) -> Aligner:
    return Aligner(device, dtype)
