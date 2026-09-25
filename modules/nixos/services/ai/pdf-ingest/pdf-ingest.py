#!/usr/bin/env python3
"""Offline PDF extraction and canonicalization for the pdf-ingest launcher.

The model-facing adapter deliberately ends at a small page/block contract.  The
canonicalizer and renderer can therefore be tested without Paddle, PyMuPDF, or
a GPU and future parser adapters do not need to change document schema v2.
The layout adapter lives in its own file, mounted at /opt/pdf-ingest/adapter.py
inside the inference container; see ParserAdapter for its contract.
"""

from __future__ import annotations

import argparse
import importlib.util
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
import time
from typing import Any, Iterable

SCHEMA_VERSION = 2
ADAPTER_MODULE = "/opt/pdf-ingest/adapter.py"
STATE_VERSION = 2
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]|\ufffd")
SPACE_RE = re.compile(r"\s+")
TEXT_TYPES = {"text", "title", "heading", "paragraph", "header", "footer", "reference", "footnote", "list_item"}
# Separator used when a table cell contains hard line breaks.  Swap to " " to
# flatten multi-line cells instead of preserving the visual break.
CELL_LINE_BREAK = "<br>"


def log(message: str) -> None:
    print(f"pdf-ingest: {message}", file=sys.stderr, flush=True)


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
    # PaddleX result objects inherit from dict, but their raw mapping contains
    # PaddleOCRVLBlock instances.  The public json view is what converts those
    # blocks to the documented block_label/block_content/block_bbox mappings,
    # so it must take precedence over generic dict traversal.
    if hasattr(value, "json"):
        candidate = value.json
        return jsonable(candidate() if callable(candidate) else candidate)
    if isinstance(value, dict):
        return {str(key): jsonable(item) for key, item in value.items() if str(key) != "img" and not isinstance(item, bytes)}
    if isinstance(value, (list, tuple)):
        return [jsonable(item) for item in value]
    if hasattr(value, "tolist"):
        return jsonable(value.tolist())
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


def point_values(value: Any) -> list[float]:
    if hasattr(value, "x") and hasattr(value, "y"):
        return [round(float(value.x), 4), round(float(value.y), 4)]
    return [round(float(item), 4) for item in value]


def serialize_link(link: dict[str, Any], display_box: Any) -> dict[str, Any]:
    item = {}
    for key, value in link.items():
        if key not in {"kind", "from", "page", "to", "uri", "xref", "id"}:
            continue
        if key == "from":
            # Convert PyMuPDF Rect objects before jsonable() falls back to
            # their human-readable "Rect(...)" representation.
            item[key] = display_box(value)
        elif key == "to" and value is not None and not isinstance(value, (str, int, float, bool)):
            item[key] = point_values(value)
        else:
            item[key] = jsonable(value)
    return item


class ParserAdapter:
    """Parser contract.

    A layout adapter module exports ADAPTER, a subclass constructed as
    ADAPTER(batch_size) inside the inference container.  Its parse_page(image,
    dpi) returns {"dpi", "render_transform", "raw", "blocks"} with block
    geometry already in PDF points.  Each block carries "raw_path", a JSON
    pointer into that page's "raw" result ("" for the whole result); the
    document's provenance links each block back to it.
    """

    name = "parser"
    model = "unknown"

    def parse_page(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
        raise NotImplementedError

    @staticmethod
    def prepare_runtime() -> None:
        """Set up caches before the first model load."""

    @staticmethod
    def metadata() -> dict[str, Any]:
        """Adapter fields of this parser's document.json parsers entry."""
        return {}

    def clear_cache(self) -> None:
        """Release accelerator memory after an OOM or before a reload."""


def load_layout_adapter() -> type[ParserAdapter]:
    # The adapter imports this module as pdf_ingest, including when it runs
    # as the __main__ script.
    sys.modules.setdefault("pdf_ingest", sys.modules[__name__])
    path = Path(os.environ.get("PDF_INGEST_ADAPTER_MODULE", ADAPTER_MODULE))
    spec = importlib.util.spec_from_file_location("pdf_ingest_adapter", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load layout adapter: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.ADAPTER


class PyMuPDFAdapter(ParserAdapter):
    name = "pymupdf"

    def __init__(self, source: Path, asset_dir: Path):
        try:
            import pymupdf as fitz
        except ImportError:
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
            links.append(serialize_link(link, display_box))

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


def model_dtype() -> str:
    return os.environ.get("PDF_INGEST_DTYPE", "float16")


def accelerator_name() -> str:
    return os.environ.get("PDF_INGEST_ACCELERATOR", "cuda")


def is_cuda_oom(error: BaseException) -> bool:
    message = str(error).lower()
    if "out of memory" not in message:
        return False
    return any(token in message for token in ("cuda", "gpu", "hip", "hsa", "resource exhausted"))


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


def choose_native(layout_text: str, candidates: list[dict[str, Any]], layout_name: str) -> tuple[str, dict[str, Any]]:
    candidates = [candidate for candidate in candidates if printable_native(candidate.get("text", ""))]
    if not candidates:
        return layout_text, {"selected": layout_name, "reason": "no_reliable_native_text", "layout_text": layout_text, "native_text": None}
    native_text = "\n".join(candidate["text"] for candidate in candidates)
    similarity = text_similarity(native_text, layout_text) if layout_text.strip() else 1.0
    if not layout_text.strip() or similarity >= 0.60:
        reason = "layout_empty" if not layout_text.strip() else "native_matches_ocr"
        return native_text, {"selected": "pymupdf", "reason": reason, "similarity": round(similarity, 4), "layout_text": layout_text, "native_text": native_text}
    return layout_text, {"selected": layout_name, "reason": "candidate_mismatch", "similarity": round(similarity, 4), "layout_text": layout_text, "native_text": native_text}


def duplicate(left: dict[str, Any], right: dict[str, Any]) -> bool:
    spatial = intersection_ratio(left["bbox"], right["bbox"]) >= 0.75
    textual = bool(normalize_text(left.get("text", ""))) and text_similarity(left.get("text", ""), right.get("text", "")) >= 0.90
    return spatial and textual


def reconcile_page(native: dict[str, Any], layout: dict[str, Any], page_number: int, layout_name: str) -> dict[str, Any]:
    blocks = []
    matched_native: set[int] = set()
    for source in layout["blocks"]:
        intersecting = []
        native_pointers = []
        for native_index, candidate in enumerate(native["blocks"]):
            if intersection_ratio(source["bbox"], candidate["bbox"]) >= 0.15:
                intersecting.append(candidate)
                native_pointers.append(f"/pages/{page_number - 1}/blocks/{native_index}")
                matched_native.add(native_index)
        text, choice = choose_native(source.get("text", ""), intersecting, layout_name) if source["type"] in TEXT_TYPES | {"caption"} else (source.get("text", ""), {"selected": layout_name, "reason": "structural_block", "layout_text": source.get("text", ""), "native_text": None})
        typed: dict[str, Any] = {}
        if source["type"] == "table":
            native_tables = [table for table in native["tables"] if table.get("bbox") and intersection_ratio(source["bbox"], table["bbox"]) >= 0.35]
            if native_tables and native_tables[0].get("cells"):
                table = native_tables[0]
                typed["table"] = {"cells": table["cells"], "rows": table["rows"], "columns": table["columns"], "source": "pymupdf"}
            else:
                cells = parse_table_markup(text)
                typed["table"] = {"cells": cells, "rows": max((cell["row"] + cell["row_span"] for cell in cells), default=0), "columns": max((cell["column"] + cell["column_span"] for cell in cells), default=0), "source": layout_name}
        if source["type"] == "formula":
            typed["formula"] = {"latex": text.strip().strip("$")}
        if source["type"] == "list_item":
            typed["list_item"] = {"marker": "unordered"}
        native_sizes = [span.get("size") for candidate in intersecting for span in candidate.get("spans", []) if span.get("size")]
        block = {
            "type": source["type"], "text": text, "bbox": source["bbox"], "polygon": source.get("polygon"),
            "source_region": source.get("label"), "links": links_for_box(native["links"], source["bbox"]),
            "provenance": {"selection": choice, "raw": {"layout": f"/pages/{page_number - 1}/result{source['raw_path']}", "pymupdf": native_pointers}},
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
            block = {"type": "text", "text": source["text"], "bbox": source["bbox"], "polygon": None, "source_region": "unmatched_native", "links": links_for_box(native["links"], source["bbox"]), "provenance": {"selection": {"selected": "pymupdf", "reason": "unmatched_native", "native_text": source["text"], "layout_text": None}, "raw": {"pymupdf": f"/pages/{page_number - 1}/blocks/{native_index}"}}}
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


def merge_split_tables(pages: list[dict[str, Any]]) -> None:
    """Rejoin a table whose continuation is the first block of the next page."""
    for previous, current in zip(pages, pages[1:]):
        if not previous["blocks"] or not current["blocks"]:
            continue
        head, tail = previous["blocks"][-1], current["blocks"][0]
        if head["type"] != "table" or tail["type"] != "table":
            continue
        target, fragment = head.get("table"), tail.get("table")
        if not target or not fragment or not target.get("columns") or target["columns"] != fragment.get("columns"):
            continue
        offset = target.get("rows", 0)
        for cell in fragment.get("cells", []):
            # The fragment's first row is a continuation, not a header.
            target["cells"].append({**cell, "row": cell["row"] + offset, "header": False})
        target["rows"] = offset + fragment.get("rows", 0)
        current["blocks"].pop(0)


def finalize_document_structure(pages: list[dict[str, Any]]) -> list[dict[str, str]]:
    """Merge split tables, renumber blocks, and apply document-wide heading ranks."""
    merge_split_tables(pages)
    relationships: list[dict[str, str]] = []
    for page in pages:
        for order, block in enumerate(page["blocks"], 1):
            block["id"] = stable_block_id(page["number"], order)
            block["reading_order"] = order
        relationships.extend(relationships_for(page["blocks"]))
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


def ocr_source_boxes(page: dict[str, Any]) -> list[list[float]]:
    """Boxes of embedded figures; text OCR'd inside them renders as code."""
    page_area = float(page.get("width") or 0) * float(page.get("height") or 0)
    boxes = []
    for block in page["blocks"]:
        if block["type"] not in {"image", "figure", "chart"} or not block.get("asset"):
            continue
        # A full-page raster is a scan, not a figure: its text is ordinary body
        # text, not content extracted from an embedded image.
        if page_area and area(block["bbox"]) >= 0.8 * page_area:
            continue
        boxes.append(block["bbox"])
    return boxes


def render_markdown(document: dict[str, Any]) -> str:
    lines = []
    footnotes = []
    for page in document["pages"]:
        ocr_boxes = ocr_source_boxes(page)
        lines.extend([f"<!-- page: {page['id']} -->", ""])
        for block in page["blocks"]:
            lines.append(f"<!-- a: {block['id']} -->")
            kind, text = block["type"], block.get("text", "")
            if kind in {"image", "figure", "chart"} and block.get("asset"):
                lines.append(f"![{sanitize_alt(text)}]({block['asset']})")
            elif kind == "table":
                lines.extend(render_table(block["table"]))
            elif kind == "formula":
                lines.extend(["$$", block["formula"]["latex"], "$$"])
            elif kind == "footnote":
                footnotes.append((block["id"], text))
            elif text.strip() and any(intersection_ratio(block["bbox"], box) >= 0.6 for box in ocr_boxes):
                lines.extend(["```", text.strip("\n"), "```"])
            elif kind in {"title", "heading"}:
                lines.append(f"{'#' * block['heading']['level']} {text}")
            elif kind == "list_item":
                lines.append(f"- {text}")
            elif text:
                lines.append(render_links(text, block.get("links", [])))
            lines.append("")
    if footnotes:
        for identifier, text in footnotes:
            lines.append(f"[^{identifier}]: {text}")
    return "\n".join(lines).rstrip() + "\n"


def escape_markdown(value: str) -> str:
    return value.replace("[", "\\[").replace("]", "\\]")


def sanitize_alt(value: str) -> str:
    return SPACE_RE.sub(" ", re.sub(r"[|!*#\[\]`<>~]", " ", value)).strip()


def cell_text(value: str) -> str:
    return re.sub(r"\s*\n\s*", CELL_LINE_BREAK, str(value).strip())


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
                # Escape first so the line-break separator stays literal markup.
                rows.append(f"    <{tag}{spans}>{cell_text(html.escape(cell['text']))}</{tag}>")
            rows.append("  </tr>")
        return rows + ["</table>"]
    row_count, column_count = table.get("rows", 0), table.get("columns", 0)
    if not row_count or not column_count:
        return ["<!-- empty table -->"]
    grid = [["" for _ in range(column_count)] for _ in range(row_count)]
    for cell in cells:
        grid[cell["row"]][cell["column"]] = cell_text(cell["text"]).replace("|", "\\|")
    return ["| " + " | ".join(row) + " |" for row in grid[:1]] + ["| " + " | ".join(["---"] * column_count) + " |"] + ["| " + " | ".join(row) + " |" for row in grid[1:]]


OLDER_OUTPUT = "pdf-ingest: destination was made by an older pdf-ingest; re-ingest into a new directory"


def probe(args: argparse.Namespace) -> int:
    output = Path(args.output)
    current = identity(args)
    entries = {entry.name for entry in output.iterdir()} if output.exists() else set()
    complete_entries = {"source.pdf", "document.json", "document.md", "images", "raw"}
    if entries == complete_entries:
        try:
            document = load_json(output / "document.json")
            version = document.get("schema_version")
            if isinstance(version, int) and version < SCHEMA_VERSION:
                print(OLDER_OUTPUT, file=sys.stderr)
                return 2
            layout = next(parser for parser in document["parsers"] if parser.get("role") == "layout")
            actual = {"source_sha256": document["document"]["source"]["sha256"], "settings": document["document"]["extraction_settings"], "image": layout["image"]}
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
        if manifest.get("state_version") != STATE_VERSION:
            print(OLDER_OUTPUT, file=sys.stderr)
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


def attach_rendered_assets(rendered: Path, layout: dict[str, Any], native: dict[str, Any], asset_dir: Path, page_number: int, dpi: int) -> None:
    figure_number = len(native["images"])
    page_image = None
    claimed_embedded: dict[str, list[float]] = {}
    for block in layout["blocks"]:
        if block["type"] not in {"figure", "chart"}:
            continue
        embedded = next((image for image in native["images"] if image.get("bbox") and intersection_ratio(block["bbox"], image["bbox"]) >= 0.65), None)
        if embedded:
            # Layout detection can split one embedded image into several
            # overlapping figure blocks; only the first may reference it.
            previous = claimed_embedded.get(embedded["asset"])
            if previous is not None and intersection_ratio(block["bbox"], previous) >= 0.65:
                continue
            claimed_embedded[embedded["asset"]] = block["bbox"]
            block["asset"] = embedded["asset"]
            continue
        figure_number += 1
        filename = f"page-{page_number:03d}-figure-{figure_number:02d}.png"
        if page_image is None:
            from PIL import Image

            page_image = Image.open(rendered)
        scale = dpi / 72.0
        left, top, right, bottom = (
            max(0, math.floor(block["bbox"][0] * scale)),
            max(0, math.floor(block["bbox"][1] * scale)),
            min(page_image.width, math.ceil(block["bbox"][2] * scale)),
            min(page_image.height, math.ceil(block["bbox"][3] * scale)),
        )
        if right > left and bottom > top:
            page_image.crop((left, top, right, bottom)).save(asset_dir / filename, format="PNG")
            block["asset"] = f"images/{filename}"
    if page_image is not None:
        page_image.close()


def prepare(args: argparse.Namespace) -> int:
    source, output = Path(args.source), Path(args.output)
    state = output / ".pdf-ingest-state"
    pages_dir, native_dir, render_dir, asset_dir = state / "pages", state / "native", state / "renders", state / "images"
    pages_dir.mkdir(parents=True, exist_ok=True)
    native_dir.mkdir(parents=True, exist_ok=True)
    render_dir.mkdir(parents=True, exist_ok=True)
    asset_dir.mkdir(parents=True, exist_ok=True)
    current_identity = identity(args)
    manifest_path = state / "manifest.json"
    if manifest_path.exists() and load_json(manifest_path).get("identity") != current_identity:
        raise RuntimeError("checkpoint identity mismatch")
    dump_json(manifest_path, {"state_version": STATE_VERSION, "identity": current_identity, "source_name": args.source_name})

    native_adapter = PyMuPDFAdapter(source, asset_dir)
    page_count = len(native_adapter.document)
    dump_json(native_dir / "metadata.json", {"page_count": page_count, "package_version": native_adapter.version})
    render_dpis = sorted({dpi for _, dpi in oom_attempts(args.batch_size, args.dpi, args.min_dpi)}, reverse=True)
    log(f"preparing {page_count} pages (native text + renders at {', '.join(str(dpi) for dpi in render_dpis)} DPI)")
    started = time.monotonic()
    for index in range(page_count):
        if (pages_dir / f"page-{index + 1:03d}.json").exists():
            continue
        native_path = native_dir / f"page-{index + 1:03d}.json"
        if not native_path.exists():
            dump_json(native_path, native_adapter.parse_page(index))
        for page_dpi in render_dpis:
            rendered = render_dir / f"page-{index + 1:03d}-{page_dpi}.png"
            if not rendered.exists():
                render_page(native_adapter.document, native_adapter.fitz, index, page_dpi, rendered)
        log(f"prepared page {index + 1}/{page_count}")
    log(f"prepare finished in {time.monotonic() - started:.1f}s")
    return 0


def infer(args: argparse.Namespace) -> int:
    output = Path(args.output)
    state = output / ".pdf-ingest-state"
    pages_dir, native_dir, render_dir, asset_dir = state / "pages", state / "native", state / "renders", state / "images"
    metadata = load_json(native_dir / "metadata.json")
    if load_json(state / "manifest.json").get("identity") != identity(args):
        raise RuntimeError("checkpoint identity mismatch")
    page_count = metadata["page_count"]
    checkpointed = sum(1 for number in range(1, page_count + 1) if (pages_dir / f"page-{number:03d}.json").exists())
    if checkpointed:
        log(f"resuming with {checkpointed}/{page_count} pages already checkpointed")
    adapter_class = load_layout_adapter()
    adapter_class.prepare_runtime()
    adapter: ParserAdapter | None = None
    loaded_batch = 0
    started = time.monotonic()
    for index in range(page_count):
        checkpoint = pages_dir / f"page-{index + 1:03d}.json"
        if checkpoint.exists():
            continue
        native = load_json(native_dir / f"page-{index + 1:03d}.json")
        page_result = None
        for attempt_batch, page_dpi in oom_attempts(args.batch_size, args.dpi, args.min_dpi):
            if adapter is None or loaded_batch != attempt_batch:
                if adapter is not None:
                    adapter.clear_cache()
                log(f"loading {adapter_class.model} model (batch {attempt_batch})")
                adapter = adapter_class(attempt_batch)
                loaded_batch = attempt_batch
                log("model ready")
            rendered = render_dir / f"page-{index + 1:03d}-{page_dpi}.png"
            log(f"page {index + 1}/{page_count}: recognizing at {page_dpi} DPI")
            page_started = time.monotonic()
            try:
                page_result = adapter.parse_page(rendered, page_dpi)
                attach_rendered_assets(rendered, page_result, native, asset_dir, index + 1, page_dpi)
                break
            except Exception as error:
                if not is_cuda_oom(error):
                    raise
                adapter.clear_cache()
                print(f"pdf-ingest: page {index + 1}: GPU OOM at batch {attempt_batch}, {page_dpi} DPI; retrying", file=sys.stderr)
        if page_result is None:
            raise RuntimeError(f"page {index + 1}: GPU OOM persisted through {args.min_dpi} DPI")
        canonical = reconcile_page(native, page_result, index + 1, adapter_class.name)
        dump_json(checkpoint, {"native": native, "layout": page_result, "canonical": canonical})
        for rendered in render_dir.glob(f"page-{index + 1:03d}-*.png"):
            rendered.unlink()
        log(f"page {index + 1}/{page_count}: done in {time.monotonic() - page_started:.1f}s ({len(canonical['blocks'])} blocks)")

    log(f"inference finished in {time.monotonic() - started:.1f}s")
    compact(args, metadata["package_version"], page_count, state, adapter_class)
    return 0


def compact(args: argparse.Namespace, pymupdf_version: str, page_count: int, state: Path, adapter: type[ParserAdapter]) -> None:
    log(f"compacting {page_count} pages into the final document")
    checkpoints = [load_json(state / "pages" / f"page-{number:03d}.json") for number in range(1, page_count + 1)]
    layouts = [checkpoint["layout"] for checkpoint in checkpoints]
    pages = [checkpoint["canonical"] for checkpoint in checkpoints]
    for page in pages:
        page.pop("relationships")
    relationships = finalize_document_structure(pages)
    document = {
        "schema_version": SCHEMA_VERSION,
        "document": {"source": {"sha256": sha256_file(Path(args.source)), "original_name": args.source_name, "path": "source.pdf", "mime_type": "application/pdf"}, "page_count": page_count, "extraction_settings": settings(args)},
        "parsers": [
            {"adapter": "pymupdf", "role": "native", "package_version": pymupdf_version, "device": "cpu", "settings": {"raw_characters": True, "links": True, "images": True, "tables": True}},
            {**adapter.metadata(), "adapter": adapter.name, "role": "layout", "model": adapter.model, "image": args.image, "accelerator": accelerator_name()},
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
    dump_json(staging / "raw" / f"{adapter.name}.json", {"adapter": adapter.name, "model": adapter.model, "pages": [{"dpi": layout["dpi"], "render_transform": layout["render_transform"], "result": layout["raw"]} for layout in layouts]})
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
    for command in ("probe", "prepare", "infer"):
        sub = commands.add_parser(command)
        sub.add_argument("--source", required=True)
        sub.add_argument("--output", required=True)
        sub.add_argument("--dpi", type=int, required=True)
        sub.add_argument("--min-dpi", type=int, required=True)
        sub.add_argument("--batch-size", type=int, required=True)
        sub.add_argument("--image", required=True)
        if command in {"prepare", "infer"}:
            sub.add_argument("--source-name", required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    if args.command == "probe":
        return probe(args)
    if args.command == "prepare":
        return prepare(args)
    return infer(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"pdf-ingest: {error}", file=sys.stderr)
        raise SystemExit(2)
