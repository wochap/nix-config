"""PaddleOCR-VL layout adapter for pdf-ingest.

pdf-ingest mounts this file at /opt/pdf-ingest/adapter.py inside the
inference container and loads ADAPTER from it.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import pdf_ingest as core

MODEL_NAME = "PaddleOCR-VL-1.6"


def initialize_paddle_cache(bundled: Path | None = None) -> None:
    """Create a writable runtime cache while retaining read-only bundled data."""
    if bundled is None:
        bundled = Path(os.environ.get("PDF_INGEST_BUNDLED_CACHE", "/home/paddleocr/.paddlex"))
    cache = Path(os.environ.get("PADDLE_PDX_CACHE_HOME", str(bundled)))
    if cache == bundled:
        return
    if not bundled.is_dir():
        raise RuntimeError(f"bundled PaddleX cache is missing: {bundled}")
    cache.mkdir(parents=True, exist_ok=True)
    for resource_name in ("official_models", "fonts"):
        source = bundled / resource_name
        target = cache / resource_name
        if source.exists() and not target.exists():
            target.symlink_to(source, target_is_directory=True)


def engine_name() -> str:
    return os.environ.get("PDF_INGEST_ENGINE", "paddle")


def paddleocr_version() -> str:
    try:
        from importlib.metadata import version

        return version("paddleocr")
    except Exception:
        return "3.6"


class PaddleOCRVLAdapter(core.ParserAdapter):
    name = "paddleocr-vl"
    model = MODEL_NAME

    def __init__(self, batch_size: int):
        from paddleocr import PaddleOCRVL

        self.pipeline = PaddleOCRVL(**self.pipeline_kwargs())
        self.batch_size = batch_size

    @staticmethod
    def prepare_runtime() -> None:
        initialize_paddle_cache()

    @staticmethod
    def metadata() -> dict[str, Any]:
        return {
            "package_version": paddleocr_version(),
            "engine": engine_name(),
            "dtype": "float16" if engine_name() == "paddle" else core.model_dtype(),
            "device": "gpu:0",
            "settings": {"all_pages": True, "layout_detection": True, "chart_recognition": True, "orientation": False, "unwarping": False, "concurrency": 1},
        }

    @staticmethod
    def pipeline_kwargs() -> dict[str, Any]:
        # Both images contain PaddleOCR-VL-1.6 weights.  Keep geometry-affecting
        # preprocessors off so pixel-to-point is affine.  "gpu:0" is passed
        # explicitly on both backends: ROCm PyTorch presents the card through
        # the CUDA API but torch.version.cuda is None there, so PaddleX would
        # otherwise fall back to the CPU.
        kwargs: dict[str, Any] = {
            "pipeline_version": "v1.6",
            "device": "gpu:0",
            "use_doc_orientation_classify": False,
            "use_doc_unwarping": False,
            "use_layout_detection": True,
            "use_chart_recognition": True,
            "use_queues": False,
            "vl_rec_backend": "native",
            "vl_rec_max_concurrency": 1,
        }
        if engine_name() == "transformers":
            # The ROCm image has no Paddle runtime; PaddleX loads the
            # safetensors checkpoints with Transformers on top of ROCm torch.
            kwargs["engine"] = "transformers"
            kwargs["engine_config"] = {"dtype": core.model_dtype()}
        else:
            # The upstream CUDA image runs PaddleOCR 3.6, which rejects unknown
            # keyword arguments, so its call stays exactly as before.
            kwargs["precision"] = "fp16"
        return kwargs

    def parse_page(self, image_path: Path, dpi: int) -> dict[str, Any]:
        try:
            results = list(self.pipeline.predict(input=str(image_path), batch_size=self.batch_size, use_queues=False))
        except TypeError:
            results = list(self.pipeline.predict(input=str(image_path), use_queues=False))
        raw = core.jsonable(results[0] if len(results) == 1 else results)
        if isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                pass
        if isinstance(raw, list) and len(raw) == 1 and isinstance(raw[0], dict):
            raw = raw[0]
        if isinstance(raw, dict) and isinstance(raw.get("res"), dict):
            raw = raw["res"]
        raw = core.portable_raw(raw)
        parsing = raw.get("parsing_res_list", []) if isinstance(raw, dict) else []
        blocks = []
        for item in parsing:
            item = core.jsonable(item)
            label = str(item.get("label", item.get("block_label", "text"))).lower()
            content = item.get("content", item.get("block_content", item.get("text", "")))
            polygon = item.get("block_polygon", item.get("polygon", item.get("poly", item.get("dt_polys"))))
            box = item.get("block_bbox", item.get("bbox", item.get("box", item.get("coordinate"))))
            if polygon and isinstance(polygon, list) and polygon and isinstance(polygon[0], (list, tuple)):
                point_polygon = core.pixel_polygon_to_points(polygon, dpi)
                point_box = core.bbox_from_polygon(point_polygon)
            else:
                point_polygon = None
                point_box = core.pixel_box_to_points(box, dpi) if box and len(box) == 4 else [0.0, 0.0, 0.0, 0.0]
            blocks.append({
                "type": core.map_label(label),
                "label": label,
                "text": str(content or ""),
                "bbox": point_box,
                "polygon": point_polygon,
                "parser_block_id": item.get("block_id", item.get("id")),
                "raw": item,
            })
        return {"dpi": dpi, "render_transform": {"pixel_to_pdf_points": round(72.0 / dpi, 8), "origin": "top-left"}, "raw": raw, "blocks": blocks}

    def clear_cache(self) -> None:
        try:
            import paddle
            paddle.device.cuda.empty_cache()
        except Exception:
            pass
        try:
            import torch
            torch.cuda.empty_cache()
        except Exception:
            pass


ADAPTER = PaddleOCRVLAdapter
