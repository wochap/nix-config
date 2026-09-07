#!/usr/bin/env python3
"""Offline PDF extraction and canonicalization for the pdf-ingest launcher.

The model-facing adapter deliberately ends at a small page/block contract.  The
canonicalizer and renderer can therefore be tested without Paddle, PyMuPDF, or
a GPU and future parser adapters do not need to change document schema v1.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import html
from html.parser import HTMLParser
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
from typing import Any, Iterable

SCHEMA_VERSION = 1
STATE_VERSION = 1
MODEL_NAME = "PaddleOCR-VL-1.6"
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]|\ufffd")
SPACE_RE = re.compile(r"\s+")
TEXT_TYPES = {"text", "title", "heading", "paragraph", "header", "footer", "reference", "footnote", "list_item"}


def dump_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def settings(args: argparse.Namespace) -> dict[str, Any]:
    return {"dpi": args.dpi, "min_dpi": args.min_dpi, "batch_size": args.batch_size}


def identity(args: argparse.Namespace) -> dict[str, Any]:
    return {"source_sha256": sha256_file(Path(args.source)), "settings": settings(args), "image": args.image}


def stable_page_id(page_number: int) -> str:
    return f"page-{page_number:03d}"


def stable_block_id(page_number: int, order: int) -> str:
    return f"p{page_number:04d}-b{order:04d}"


def normalize_text(value: str) -> str:
    return SPACE_RE.sub(" ", value).strip().casefold()


def printable_native(value: str) -> bool:
    value = value.strip()
    return bool(value) and not CONTROL_RE.search(value) and sum(character.isprintable() for character in value) / len(value) >= 0.98


def text_similarity(left: str, right: str) -> float:
    return difflib.SequenceMatcher(None, normalize_text(left), normalize_text(right)).ratio()


def area(box: list[float]) -> float:
    return max(0.0, box[2] - box[0]) * max(0.0, box[3] - box[1])


def intersection_ratio(left: list[float], right: list[float]) -> float:
    overlap = [max(left[0], right[0]), max(left[1], right[1]), min(left[2], right[2]), min(left[3], right[3])]
    overlap_area = area(overlap)
    return overlap_area / min(area(left), area(right)) if overlap_area and min(area(left), area(right)) else 0.0


def pixel_box_to_points(box: Iterable[float], dpi: int) -> list[float]:
    scale = 72.0 / dpi
    values = list(box)
    return [round(float(value) * scale, 4) for value in values]


def pixel_polygon_to_points(polygon: Iterable[Iterable[float]], dpi: int) -> list[list[float]]:
    scale = 72.0 / dpi
    return [[round(float(x) * scale, 4), round(float(y) * scale, 4)] for x, y in polygon]


def bbox_from_polygon(polygon: list[list[float]]) -> list[float]:
    xs = [point[0] for point in polygon]
    ys = [point[1] for point in polygon]
    return [min(xs), min(ys), max(xs), max(ys)]


def jsonable(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, dict):
        return {str(key): jsonable(item) for key, item in value.items() if str(key) != "img" and not isinstance(item, bytes)}
    if isinstance(value, (list, tuple)):
        return [jsonable(item) for item in value]
    if hasattr(value, "tolist"):
        return jsonable(value.tolist())
    if hasattr(value, "json"):
        candidate = value.json
        return jsonable(candidate() if callable(candidate) else candidate)
    if hasattr(value, "res"):
        return jsonable(value.res)
    return str(value)


def portable_raw(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: portable_raw(item) for key, item in value.items()}
    if isinstance(value, list):
        return [portable_raw(item) for item in value]
    if isinstance(value, str):
        if value == "/input/source.pdf":
            return "source.pdf"
        if value.startswith("/output/"):
            return value.removeprefix("/output/")
    return value


class ParserAdapter:
    name = "parser"

    def parse_page(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
        raise NotImplementedError


class PyMuPDFAdapter(ParserAdapter):
    name = "pymupdf"

    def __init__(self, source: Path, asset_dir: Path):
        import fitz

        self.fitz = fitz
        self.document = fitz.open(source)
        self.asset_dir = asset_dir

    @property
    def version(self) -> str:
        return str(getattr(self.fitz, "VersionBind", "unknown"))

    def parse_page(self, index: int) -> dict[str, Any]:
        page = self.document[index]
        rawdict = page.get_text("rawdict")
        def display_box(values: Iterable[float]) -> list[float]:
            rect = self.fitz.Rect(*values)
            if page.rotation:
                rect = rect * page.rotation_matrix
            return [round(float(value), 4) for value in rect]

        native_blocks: list[dict[str, Any]] = []
        for raw_block in rawdict.get("blocks", []):
            if raw_block.get("type") != 0:
                continue
            spans = []
            text_parts = []
            for line in raw_block.get("lines", []):
                line_text = []
                for span in line.get("spans", []):
                    characters = span.get("chars", [])
                    span_text = "".join(character.get("c", "") for character in characters)
                    line_text.append(span_text)
                    spans.append({
                        "text": span_text,
                        "bbox": display_box(span.get("bbox", [0, 0, 0, 0])),
                        "font": span.get("font"),
                        "size": span.get("size"),
                        "flags": span.get("flags"),
                        "characters": [{"c": c.get("c", ""), "bbox": c.get("bbox")} for c in characters],
                    })
                text_parts.append("".join(line_text))
            text = "\n".join(text_parts).strip()
            if text:
                native_blocks.append({"type": "text", "text": text, "bbox": display_box(raw_block.get("bbox", [0, 0, 0, 0])), "spans": spans})

        images = []
        seen_xrefs = set()
        for info in page.get_images(full=True):
            xref = int(info[0])
            if xref in seen_xrefs:
                continue
            seen_xrefs.add(xref)
            image_number = len(images) + 1
            extracted = self.document.extract_image(xref)
            extension = extracted.get("ext", "bin").lower()
            filename = f"page-{index + 1:03d}-figure-{image_number:02d}.{extension}"
            (self.asset_dir / filename).write_bytes(extracted["image"])
            rects = page.get_image_rects(xref)
            images.append({
                "xref": xref,
                "asset": f"images/{filename}",
                "bbox": display_box(rects[0]) if rects else None,
                "width": extracted.get("width"),
                "height": extracted.get("height"),
                "encoding": extension,
            })

        tables = []
        finder = getattr(page, "find_tables", None)
        if finder:
            try:
                for table in finder().tables:
                    extracted = table.extract()
                    cells = normalize_grid(extracted)
                    tables.append({"bbox": display_box(table.bbox), "cells": cells, "rows": len(extracted), "columns": max((len(row) for row in extracted), default=0)})
            except Exception as error:
                tables.append({"error": str(error)})

        links = []
        for link in page.get_links():
            item = {key: jsonable(value) for key, value in link.items() if key in {"kind", "from", "page", "to", "uri", "xref", "id"}}
            if "from" in item:
                item["from"] = display_box(item["from"])
            if "to" in item and not isinstance(item["to"], (str, int, float, bool, type(None))):
                item["to"] = list(item["to"])
            links.append(item)

        rect = page.rect
        return {
            "page_number": index + 1,
            "width": round(rect.width, 4),
            "height": round(rect.height, 4),
            "rotation": page.rotation,
            "blocks": native_blocks,
            "links": links,
            "images": images,
            "tables": tables,
            "rawdict": jsonable(rawdict),
        }


class PaddleOCRVLAdapter(ParserAdapter):
    name = "paddleocr-vl"

    def __init__(self, batch_size: int):
        from paddleocr import PaddleOCRVL

        # PaddleOCR 3.6's offline image contains PaddleOCR-VL-1.6 weights.  Keep
        # geometry-affecting preprocessors off so pixel-to-point is affine.
        kwargs = {
            "pipeline_version": "v1.6",
            "device": "gpu:0",
            "precision": "fp16",
            "use_doc_orientation_classify": False,
            "use_doc_unwarping": False,
            "use_layout_detection": True,
            "use_chart_recognition": True,
            "use_queues": False,
            "vl_rec_backend": "native",
            "vl_rec_max_concurrency": 1,
        }
        self.pipeline = PaddleOCRVL(**kwargs)
        self.batch_size = batch_size

    def parse_page(self, image_path: Path, dpi: int) -> dict[str, Any]:
        try:
            results = list(self.pipeline.predict(input=str(image_path), batch_size=self.batch_size, use_queues=False))
        except TypeError:
            results = list(self.pipeline.predict(input=str(image_path), use_queues=False))
        raw = jsonable(results[0] if len(results) == 1 else results)
        if isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                pass
        if isinstance(raw, list) and len(raw) == 1 and isinstance(raw[0], dict):
            raw = raw[0]
        if isinstance(raw, dict) and isinstance(raw.get("res"), dict):
            raw = raw["res"]
        raw = portable_raw(raw)
        parsing = raw.get("parsing_res_list", []) if isinstance(raw, dict) else []
        blocks = []
        for item in parsing:
            item = jsonable(item)
            label = str(item.get("label", item.get("block_label", "text"))).lower()
            content = item.get("content", item.get("block_content", item.get("text", "")))
            polygon = item.get("block_polygon", item.get("polygon", item.get("poly", item.get("dt_polys"))))
            box = item.get("block_bbox", item.get("bbox", item.get("box", item.get("coordinate"))))
            if polygon and isinstance(polygon, list) and polygon and isinstance(polygon[0], (list, tuple)):
                point_polygon = pixel_polygon_to_points(polygon, dpi)
                point_box = bbox_from_polygon(point_polygon)
            else:
                point_polygon = None
                point_box = pixel_box_to_points(box, dpi) if box and len(box) == 4 else [0.0, 0.0, 0.0, 0.0]
            blocks.append({
                "type": map_label(label),
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


def is_cuda_oom(error: BaseException) -> bool:
    message = str(error).lower()
    return "out of memory" in message and ("cuda" in message or "gpu" in message or "resource exhausted" in message)


def retry_dpis(initial: int, minimum: int) -> list[int]:
    values = [initial]
    while values[-1] > minimum:
        next_value = max(minimum, values[-1] // 2)
        if next_value == values[-1]:
            break
        values.append(next_value)
    return values


def oom_attempts(batch_size: int, initial_dpi: int, minimum_dpi: int) -> list[tuple[int, int]]:
    """Retry batch reductions at full DPI before reducing render resolution."""
    attempts = []
    batch = batch_size
    while batch > 1:
        attempts.append((batch, initial_dpi))
        batch = max(1, batch // 2)
    attempts.extend((batch, dpi) for dpi in retry_dpis(initial_dpi, minimum_dpi))
    return attempts


def map_label(label: str) -> str:
    normalized = label.replace("-", "_").replace(" ", "_")
    aliases = {"doc_title": "title", "document_title": "title", "paragraph_title": "heading", "section_title": "heading", "table_caption": "caption", "figure_caption": "caption", "image": "figure", "chart": "chart", "equation": "formula", "formula": "formula", "list": "list_item"}
    return aliases.get(normalized, normalized if normalized in TEXT_TYPES | {"table", "figure", "chart", "formula", "caption"} else "text")


class TableHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.cells: list[dict[str, Any]] = []
        self.row = -1
        self.column = 0
        self.current: dict[str, Any] | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag == "tr":
            self.row += 1
            self.column = 0
        elif tag in {"td", "th"}:
            self.current = {"row": max(self.row, 0), "column": self.column, "row_span": int(attributes.get("rowspan") or 1), "column_span": int(attributes.get("colspan") or 1), "header": tag == "th", "text": ""}
            self.column += self.current["column_span"]

    def handle_data(self, data: str) -> None:
        if self.current is not None:
            self.current["text"] += data

    def handle_endtag(self, tag: str) -> None:
        if tag in {"td", "th"} and self.current is not None:
            self.current["text"] = SPACE_RE.sub(" ", self.current["text"]).strip()
            self.cells.append(self.current)
            self.current = None


def parse_table_markup(value: str) -> list[dict[str, Any]]:
    parser = TableHTMLParser()
    if "<table" in value.lower():
        parser.feed(value)
        return parser.cells
    rows = [line.strip().strip("|") for line in value.splitlines() if "|" in line]
    rows = [row for row in rows if not re.fullmatch(r"[\s:|\-]+", row)]
    return normalize_grid([[cell.strip() for cell in row.split("|")] for row in rows])


def normalize_grid(rows: list[list[Any]]) -> list[dict[str, Any]]:
    return [{"row": row_number, "column": column_number, "row_span": 1, "column_span": 1, "header": row_number == 0, "text": str(value or "").strip()} for row_number, row in enumerate(rows) for column_number, value in enumerate(row)]


def choose_native(paddle_text: str, candidates: list[dict[str, Any]]) -> tuple[str, dict[str, Any]]:
    candidates = [candidate for candidate in candidates if printable_native(candidate.get("text", ""))]
    if not candidates:
        return paddle_text, {"selected": "paddleocr-vl", "reason": "no_reliable_native_text", "paddle_text": paddle_text, "native_text": None}
    native_text = "\n".join(candidate["text"] for candidate in candidates)
    similarity = text_similarity(native_text, paddle_text) if paddle_text.strip() else 1.0
    if not paddle_text.strip() or similarity >= 0.60:
        reason = "paddle_empty" if not paddle_text.strip() else "native_matches_ocr"
        return native_text, {"selected": "pymupdf", "reason": reason, "similarity": round(similarity, 4), "paddle_text": paddle_text, "native_text": native_text}
    return paddle_text, {"selected": "paddleocr-vl", "reason": "candidate_mismatch", "similarity": round(similarity, 4), "paddle_text": paddle_text, "native_text": native_text}


def duplicate(left: dict[str, Any], right: dict[str, Any]) -> bool:
    spatial = intersection_ratio(left["bbox"], right["bbox"]) >= 0.75
    textual = bool(normalize_text(left.get("text", ""))) and text_similarity(left.get("text", ""), right.get("text", "")) >= 0.90
    return spatial and textual


def reconcile_page(native: dict[str, Any], paddle: dict[str, Any], page_number: int) -> dict[str, Any]:
    blocks = []
    matched_native: set[int] = set()
    for paddle_index, source in enumerate(paddle["blocks"]):
        intersecting = []
        native_pointers = []
        for native_index, candidate in enumerate(native["blocks"]):
            if intersection_ratio(source["bbox"], candidate["bbox"]) >= 0.15:
                intersecting.append(candidate)
                native_pointers.append(f"/pages/{page_number - 1}/blocks/{native_index}")
                matched_native.add(native_index)
        text, choice = choose_native(source.get("text", ""), intersecting) if source["type"] in TEXT_TYPES | {"caption"} else (source.get("text", ""), {"selected": "paddleocr-vl", "reason": "structural_block", "paddle_text": source.get("text", ""), "native_text": None})
        typed: dict[str, Any] = {}
        if source["type"] == "table":
            native_tables = [table for table in native["tables"] if table.get("bbox") and intersection_ratio(source["bbox"], table["bbox"]) >= 0.35]
            if native_tables and native_tables[0].get("cells"):
                table = native_tables[0]
                typed["table"] = {"cells": table["cells"], "rows": table["rows"], "columns": table["columns"], "source": "pymupdf"}
            else:
                cells = parse_table_markup(text)
                typed["table"] = {"cells": cells, "rows": max((cell["row"] + cell["row_span"] for cell in cells), default=0), "columns": max((cell["column"] + cell["column_span"] for cell in cells), default=0), "source": "paddleocr-vl"}
        if source["type"] == "formula":
            typed["formula"] = {"latex": text.strip().strip("$")}
        if source["type"] == "list_item":
            typed["list_item"] = {"marker": "unordered"}
        native_sizes = [span.get("size") for candidate in intersecting for span in candidate.get("spans", []) if span.get("size")]
        block = {
            "type": source["type"], "text": text, "bbox": source["bbox"], "polygon": source.get("polygon"),
            "source_region": source.get("label"), "links": links_for_box(native["links"], source["bbox"]),
            "provenance": {"selection": choice, "raw": {"paddleocr_vl": f"/pages/{page_number - 1}/result/parsing_res_list/{paddle_index}", "pymupdf": native_pointers}},
            **typed,
        }
        if native_sizes:
            block["_native_font_size"] = max(native_sizes)
        if source.get("asset"):
            block["asset"] = source["asset"]
            block[source["type"]] = {"asset": source["asset"], "source": "rendered_crop"}
        if not any(duplicate(block, existing) for existing in blocks):
            blocks.append(block)

    for native_index, source in enumerate(native["blocks"]):
        if native_index not in matched_native:
            block = {"type": "text", "text": source["text"], "bbox": source["bbox"], "polygon": None, "source_region": "unmatched_native", "links": links_for_box(native["links"], source["bbox"]), "provenance": {"selection": {"selected": "pymupdf", "reason": "unmatched_native", "native_text": source["text"], "paddle_text": None}, "raw": {"pymupdf": f"/pages/{page_number - 1}/blocks/{native_index}"}}}
            if printable_native(source["text"]) and not any(duplicate(block, existing) for existing in blocks):
                blocks.append(block)

    add_image_blocks(blocks, native, page_number)
    infer_headings(blocks)
    section_path: list[str] = []
    for order, block in enumerate(blocks, 1):
        block["id"] = stable_block_id(page_number, order)
        block["reading_order"] = order
        if block["type"] in {"title", "heading"}:
            level = block["heading"]["level"]
            section_path = section_path[: level - 1] + [block["text"]]
        block["section_path"] = section_path.copy()
    relationships = relationships_for(blocks)
    return {"id": stable_page_id(page_number), "number": page_number, "width": native["width"], "height": native["height"], "rotation": native["rotation"], "coordinate_space": {"origin": "top-left", "units": "pdf-points", "orientation": "displayed-page"}, "blocks": blocks, "relationships": relationships}


def links_for_box(links: list[dict[str, Any]], box: list[float]) -> list[dict[str, Any]]:
    return [link for link in links if link.get("from") and intersection_ratio(box, link["from"]) > 0]


def add_image_blocks(blocks: list[dict[str, Any]], native: dict[str, Any], page_number: int) -> None:
    for image_number, image in enumerate(native["images"], 1):
        if not image.get("bbox"):
            continue
        image_type = "image"
        candidate = {"type": image_type, "text": "", "bbox": image["bbox"], "polygon": None, "source_region": "embedded_image", "links": [], "asset": image["asset"], "image": {key: image.get(key) for key in ("width", "height", "encoding")}, "provenance": {"selection": {"selected": "pymupdf", "reason": "original_embedded_asset"}, "raw": {"pymupdf": f"/pages/{page_number - 1}/images/{image_number - 1}"}}}
        if not any(existing["type"] in {"figure", "chart"} and intersection_ratio(existing["bbox"], candidate["bbox"]) >= 0.65 for existing in blocks):
            blocks.append(candidate)


def infer_headings(blocks: list[dict[str, Any]]) -> None:
    native_sizes = sorted({block["_native_font_size"] for block in blocks if block["type"] == "heading" and block.get("_native_font_size")}, reverse=True)
    title_seen = False
    surrounding_level = 2
    for block in blocks:
        if block["type"] == "title" and not title_seen:
            block["heading"] = {"level": 1, "native_font_size": block.get("_native_font_size")}
            title_seen = True
        elif block["type"] in {"title", "heading"}:
            block["type"] = "heading"
            size = block.get("_native_font_size")
            level = min(6, 2 + native_sizes.index(size)) if size in native_sizes else surrounding_level
            block["heading"] = {"level": level, "native_font_size": size}
            surrounding_level = level
        block.pop("_native_font_size", None)


def relationships_for(blocks: list[dict[str, Any]]) -> list[dict[str, str]]:
    relationships = []
    for previous, current in zip(blocks, blocks[1:]):
        relationships.append({"type": "follows", "from": current["id"], "to": previous["id"]})
    visual = [block for block in blocks if block["type"] in {"image", "figure", "chart", "table"}]
    for caption in [block for block in blocks if block["type"] == "caption"]:
        if visual:
            target = min(visual, key=lambda item: (abs(item["bbox"][1] - caption["bbox"][3]), item["reading_order"]))
            relationships.append({"type": "caption_of", "from": caption["id"], "to": target["id"]})
    heading_stack: list[dict[str, Any]] = []
    for block in blocks:
        if block["type"] in {"title", "heading"}:
            level = block["heading"]["level"]
            heading_stack = [item for item in heading_stack if item["heading"]["level"] < level]
            heading_stack.append(block)
        elif heading_stack:
            relationships.append({"type": "contains", "from": heading_stack[-1]["id"], "to": block["id"]})
        for link in block.get("links", []):
            if isinstance(link.get("page"), int) and link["page"] >= 0:
                relationships.append({"type": "internal_link", "from": block["id"], "to": stable_page_id(link["page"] + 1)})
    return relationships


def finalize_document_structure(pages: list[dict[str, Any]], relationships: list[dict[str, str]]) -> list[dict[str, str]]:
    """Apply document-wide heading ranks and section containment."""
    all_blocks = [block for page in pages for block in page["blocks"]]
    document_title = next((block for block in all_blocks if block["type"] == "title"), None)
    heading_sizes = sorted({block.get("heading", {}).get("native_font_size") for block in all_blocks if block is not document_title and block["type"] in {"title", "heading"} and block.get("heading", {}).get("native_font_size")}, reverse=True)
    current_level = 2
    section_stack: list[dict[str, Any]] = []
    relationships = [item for item in relationships if item["type"] != "contains"]
    for block in all_blocks:
        if block is document_title:
            block["heading"]["level"] = 1
        elif block["type"] in {"title", "heading"}:
            block["type"] = "heading"
            size = block["heading"].get("native_font_size")
            current_level = min(6, 2 + heading_sizes.index(size)) if size in heading_sizes else current_level
            block["heading"]["level"] = current_level
        if block["type"] in {"title", "heading"}:
            level = block["heading"]["level"]
            section_stack = [item for item in section_stack if item["heading"]["level"] < level]
            section_stack.append(block)
        block["section_path"] = [item["text"] for item in section_stack]
        if block["type"] not in {"title", "heading"} and section_stack:
            relationships.append({"type": "contains", "from": section_stack[-1]["id"], "to": block["id"]})
        if "heading" in block and block["heading"].get("native_font_size") is None:
            block["heading"].pop("native_font_size", None)
    return relationships


def validate_document(document: dict[str, Any]) -> None:
    required = {"schema_version", "document", "parsers", "pages", "relationships"}
    if not required <= document.keys() or document["schema_version"] != SCHEMA_VERSION:
        raise ValueError("invalid document schema header")
    seen = set()
    for page_number, page in enumerate(document["pages"], 1):
        if page["id"] != stable_page_id(page_number) or page["number"] != page_number:
            raise ValueError("unstable page identity")
        for order, block in enumerate(page["blocks"], 1):
            if block["id"] != stable_block_id(page_number, order) or block["id"] in seen:
                raise ValueError("unstable or duplicate block identity")
            seen.add(block["id"])
            box = block["bbox"]
            if len(box) != 4 or not all(isinstance(value, (int, float)) and math.isfinite(value) for value in box):
                raise ValueError(f"invalid bbox for {block['id']}")


def render_markdown(document: dict[str, Any]) -> str:
    lines = []
    footnotes = []
    for page in document["pages"]:
        lines.extend([f"<!-- page: {page['id']} -->", ""])
        for block in page["blocks"]:
            lines.append(f"<a id=\"{block['id']}\"></a>")
            kind, text = block["type"], block.get("text", "")
            if kind in {"title", "heading"}:
                lines.append(f"{'#' * block['heading']['level']} {text}")
            elif kind == "list_item":
                lines.append(f"- {text}")
            elif kind == "table":
                lines.extend(render_table(block["table"]))
            elif kind == "formula":
                lines.extend(["$$", block["formula"]["latex"], "$$"])
            elif kind in {"image", "figure", "chart"} and block.get("asset"):
                lines.append(f"![{escape_markdown(text)}]({block['asset']})")
            elif kind == "footnote":
                footnotes.append((block["id"], text))
            elif text:
                lines.append(render_links(text, block.get("links", [])))
            lines.append("")
    if footnotes:
        for identifier, text in footnotes:
            lines.append(f"[^{identifier}]: {text}")
    return "\n".join(lines).rstrip() + "\n"


def escape_markdown(value: str) -> str:
    return value.replace("[", "\\[").replace("]", "\\]")


def render_links(text: str, links: list[dict[str, Any]]) -> str:
    uris = [link.get("uri") for link in links if link.get("uri")]
    return f"[{escape_markdown(text)}]({uris[0]})" if len(uris) == 1 else text


def render_table(table: dict[str, Any]) -> list[str]:
    cells = table.get("cells", [])
    if any(cell.get("row_span", 1) > 1 or cell.get("column_span", 1) > 1 for cell in cells):
        rows = ["<table>"]
        for row_number in range(table.get("rows", 0)):
            rows.append("  <tr>")
            for cell in [item for item in cells if item["row"] == row_number]:
                tag = "th" if cell.get("header") else "td"
                spans = (f' rowspan="{cell["row_span"]}"' if cell.get("row_span", 1) > 1 else "") + (f' colspan="{cell["column_span"]}"' if cell.get("column_span", 1) > 1 else "")
                rows.append(f"    <{tag}{spans}>{html.escape(cell['text'])}</{tag}>")
            rows.append("  </tr>")
        return rows + ["</table>"]
    row_count, column_count = table.get("rows", 0), table.get("columns", 0)
    if not row_count or not column_count:
        return ["<!-- empty table -->"]
    grid = [["" for _ in range(column_count)] for _ in range(row_count)]
    for cell in cells:
        grid[cell["row"]][cell["column"]] = cell["text"].replace("|", "\\|")
    return ["| " + " | ".join(row) + " |" for row in grid[:1]] + ["| " + " | ".join(["---"] * column_count) + " |"] + ["| " + " | ".join(row) + " |" for row in grid[1:]]


def probe(args: argparse.Namespace) -> int:
    output = Path(args.output)
    current = identity(args)
    entries = {entry.name for entry in output.iterdir()} if output.exists() else set()
    complete_entries = {"source.pdf", "document.json", "document.md", "images", "raw"}
    if entries == complete_entries:
        try:
            document = load_json(output / "document.json")
            actual = {"source_sha256": document["document"]["source"]["sha256"], "settings": document["document"]["extraction_settings"], "image": document["parsers"][1]["image"]}
            validate_document(document)
        except Exception as error:
            print(f"pdf-ingest: destination looks complete but is invalid: {error}", file=sys.stderr)
            return 2
        if actual == current:
            return 0
        print("pdf-ingest: destination contains a result for a different source or settings", file=sys.stderr)
        return 2
    allowed = {".pdf-ingest-state"}
    manifest_path = output / ".pdf-ingest-state" / "manifest.json"
    if manifest_path.exists():
        try:
            manifest = load_json(manifest_path)
        except Exception as error:
            print(f"pdf-ingest: unreadable checkpoint manifest: {error}", file=sys.stderr)
            return 2
        if manifest.get("identity") != current:
            print("pdf-ingest: checkpoint belongs to a different source or settings", file=sys.stderr)
            return 2
        # A process can be interrupted between atomic artifact renames.  Only
        # canonical final names are accepted alongside a matching manifest.
        if entries - allowed - complete_entries:
            print("pdf-ingest: refusing unrelated files beside matching checkpoints", file=sys.stderr)
            return 2
        print("pdf-ingest: resuming matching checkpoints", file=sys.stderr)
    elif entries - allowed:
        print("pdf-ingest: refusing unrelated non-empty destination", file=sys.stderr)
        return 2
    return 10


def render_page(document: Any, fitz: Any, index: int, dpi: int, target: Path) -> None:
    page = document[index]
    matrix = fitz.Matrix(dpi / 72.0, dpi / 72.0)
    page.get_pixmap(matrix=matrix, alpha=False).save(target)


def attach_rendered_assets(page: Any, fitz: Any, paddle: dict[str, Any], native: dict[str, Any], asset_dir: Path, page_number: int, dpi: int) -> None:
    figure_number = len(native["images"])
    matrix = fitz.Matrix(dpi / 72.0, dpi / 72.0)
    for block in paddle["blocks"]:
        if block["type"] not in {"figure", "chart"}:
            continue
        embedded = next((image for image in native["images"] if image.get("bbox") and intersection_ratio(block["bbox"], image["bbox"]) >= 0.65), None)
        if embedded:
            block["asset"] = embedded["asset"]
            continue
        figure_number += 1
        filename = f"page-{page_number:03d}-figure-{figure_number:02d}.png"
        display_clip = fitz.Rect(*block["bbox"]) & page.rect
        clip = display_clip * page.derotation_matrix if page.rotation else display_clip
        if not display_clip.is_empty:
            page.get_pixmap(matrix=matrix, clip=clip, alpha=False).save(asset_dir / filename)
            block["asset"] = f"images/{filename}"


def ingest(args: argparse.Namespace) -> int:
    source, output = Path(args.source), Path(args.output)
    state = output / ".pdf-ingest-state"
    pages_dir, asset_dir = state / "pages", state / "images"
    pages_dir.mkdir(parents=True, exist_ok=True)
    asset_dir.mkdir(parents=True, exist_ok=True)
    current_identity = identity(args)
    manifest_path = state / "manifest.json"
    if manifest_path.exists() and load_json(manifest_path).get("identity") != current_identity:
        raise RuntimeError("checkpoint identity mismatch")
    dump_json(manifest_path, {"state_version": STATE_VERSION, "identity": current_identity, "source_name": args.source_name})

    native_adapter = PyMuPDFAdapter(source, asset_dir)
    paddle_adapter: PaddleOCRVLAdapter | None = None
    loaded_batch = 0
    for index in range(len(native_adapter.document)):
        checkpoint = pages_dir / f"page-{index + 1:03d}.json"
        if checkpoint.exists():
            continue
        native = native_adapter.parse_page(index)
        page_result = None
        for attempt_batch, page_dpi in oom_attempts(args.batch_size, args.dpi, args.min_dpi):
            if paddle_adapter is None or loaded_batch != attempt_batch:
                if paddle_adapter is not None:
                    paddle_adapter.clear_cache()
                paddle_adapter = PaddleOCRVLAdapter(attempt_batch)
                loaded_batch = attempt_batch
            rendered = state / f"render-{index + 1:03d}-{page_dpi}.png"
            render_page(native_adapter.document, native_adapter.fitz, index, page_dpi, rendered)
            try:
                page_result = paddle_adapter.parse_page(rendered, page_dpi)
                attach_rendered_assets(native_adapter.document[index], native_adapter.fitz, page_result, native, asset_dir, index + 1, page_dpi)
                rendered.unlink(missing_ok=True)
                break
            except Exception as error:
                rendered.unlink(missing_ok=True)
                if not is_cuda_oom(error):
                    raise
                paddle_adapter.clear_cache()
                print(f"pdf-ingest: page {index + 1}: CUDA OOM at batch {attempt_batch}, {page_dpi} DPI; retrying", file=sys.stderr)
        if page_result is None:
            raise RuntimeError(f"page {index + 1}: CUDA OOM persisted through {args.min_dpi} DPI")
        canonical = reconcile_page(native, page_result, index + 1)
        dump_json(checkpoint, {"native": native, "paddle": page_result, "canonical": canonical})

    compact(args, native_adapter.version, len(native_adapter.document), state)
    return 0


def compact(args: argparse.Namespace, pymupdf_version: str, page_count: int, state: Path) -> None:
    checkpoints = [load_json(state / "pages" / f"page-{number:03d}.json") for number in range(1, page_count + 1)]
    pages = [checkpoint["canonical"] for checkpoint in checkpoints]
    relationships = [relationship for page in pages for relationship in page.pop("relationships")]
    relationships = finalize_document_structure(pages, relationships)
    document = {
        "schema_version": SCHEMA_VERSION,
        "document": {"source": {"sha256": sha256_file(Path(args.source)), "original_name": args.source_name, "path": "source.pdf", "mime_type": "application/pdf"}, "page_count": page_count, "extraction_settings": settings(args)},
        "parsers": [
            {"adapter": "pymupdf", "package_version": pymupdf_version, "device": "cpu", "settings": {"raw_characters": True, "links": True, "images": True, "tables": True}},
            {"adapter": "paddleocr-vl", "package_version": "3.6", "model": MODEL_NAME, "image": args.image, "precision": "fp16", "device": "gpu:0", "settings": {"all_pages": True, "layout_detection": True, "chart_recognition": True, "orientation": False, "unwarping": False, "concurrency": 1}},
        ],
        "pages": pages,
        "relationships": relationships,
    }
    validate_document(document)
    staging = state / "final"
    if staging.exists():
        shutil.rmtree(staging)
    (staging / "raw").mkdir(parents=True)
    shutil.copy2(args.source, staging / "source.pdf")
    shutil.copytree(state / "images", staging / "images")
    dump_json(staging / "raw" / "pymupdf.json", {"adapter": "pymupdf", "pages": [checkpoint["native"] for checkpoint in checkpoints]})
    dump_json(staging / "raw" / "paddleocr-vl.json", {"adapter": "paddleocr-vl", "model": MODEL_NAME, "pages": [{"dpi": checkpoint["paddle"]["dpi"], "render_transform": checkpoint["paddle"]["render_transform"], "result": checkpoint["paddle"]["raw"]} for checkpoint in checkpoints]})
    dump_json(staging / "document.json", document)
    (staging / "document.md").write_text(render_markdown(load_json(staging / "document.json")), encoding="utf-8")
    output = Path(args.output)
    for name in ("source.pdf", "document.json", "document.md", "images", "raw"):
        existing = output / name
        if existing.is_dir():
            shutil.rmtree(existing)
        os.replace(staging / name, output / name)
    shutil.rmtree(state)


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(dest="command", required=True)
    for command in ("probe", "ingest"):
        sub = commands.add_parser(command)
        sub.add_argument("--source", required=True)
        sub.add_argument("--output", required=True)
        sub.add_argument("--dpi", type=int, required=True)
        sub.add_argument("--min-dpi", type=int, required=True)
        sub.add_argument("--batch-size", type=int, required=True)
        sub.add_argument("--image", required=True)
        if command == "ingest":
            sub.add_argument("--source-name", required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    return probe(args) if args.command == "probe" else ingest(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError) as error:
        print(f"pdf-ingest: {error}", file=sys.stderr)
        raise SystemExit(2)
