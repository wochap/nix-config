"""Qwen3-ASR adapter: Qwen3-ASR-1.7B plus Qwen3-ForcedAligner-0.6B."""

from dataclasses import dataclass

# The pipeline passes ISO 639 codes; qwen-asr expects these English names.
QWEN_LANGUAGES = {
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


def qwen_language(code: str | None) -> str | None:
    if code is None:
        return None
    return QWEN_LANGUAGES.get(code, code)


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
    def __init__(self, device: str, dtype: str, batch_size: int, model: dict[str, str]) -> None:
        import torch
        from qwen_asr import Qwen3ASRModel

        self.model = Qwen3ASRModel.from_pretrained(
            model["repo"],
            revision=model["revision"],
            dtype=getattr(torch, dtype),
            device_map=device,
            max_inference_batch_size=batch_size,
            max_new_tokens=4096,
        )

    def transcribe(self, paths: list[str], language: str | None) -> list[Transcript]:
        results = self.model.transcribe(audio=paths, language=qwen_language(language))
        return [Transcript(result.text, result.language) for result in results]


class Aligner:
    def __init__(self, device: str, dtype: str, model: dict[str, str]) -> None:
        import torch
        from qwen_asr import Qwen3ForcedAligner

        self.model = Qwen3ForcedAligner.from_pretrained(
            model["repo"],
            revision=model["revision"],
            dtype=getattr(torch, dtype),
            device_map=device,
        )

    def align(self, path: str, text: str, language: str) -> list[Unit]:
        aligned = self.model.align(audio=path, text=text, language=qwen_language(language))[0]
        return [Unit(item.text, item.start_time, item.end_time) for item in aligned]


def load_transcriber(
    device: str, dtype: str, batch_size: int, models: dict[str, dict[str, str]]
) -> Transcriber:
    return Transcriber(device, dtype, batch_size, models["asr"])


def load_aligner(device: str, dtype: str, models: dict[str, dict[str, str]]) -> Aligner:
    return Aligner(device, dtype, models["aligner"])
