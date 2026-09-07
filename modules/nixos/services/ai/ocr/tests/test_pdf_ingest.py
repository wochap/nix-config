from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = Path(__file__).parents[1] / "pdf-ingest.py"
SPEC = importlib.util.spec_from_file_location("pdf_ingest", MODULE_PATH)
pdf = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(pdf)


def native_page(blocks=None, tables=None, images=None, links=None, rotation=0):
    return {
        "page_number": 1,
        "width": 612.0,
        "height": 792.0,
        "rotation": rotation,
        "blocks": blocks or [],
        "tables": tables or [],
        "images": images or [],
        "links": links or [],
        "rawdict": {},
    }


def native_block(text, bbox, size=11):
    return {"type": "text", "text": text, "bbox": bbox, "spans": [{"text": text, "bbox": bbox, "size": size, "characters": []}]}


def paddle_page(blocks):
    return {"dpi": 200, "render_transform": {"pixel_to_pdf_points": 0.36}, "raw": {"parsing_res_list": []}, "blocks": blocks}


def paddle_block(kind, text, bbox, label=None, asset=None):
    result = {"type": kind, "label": label or kind, "text": text, "bbox": bbox, "polygon": None, "raw": {}}
    if asset:
        result["asset"] = asset
    return result


class GeometryTests(unittest.TestCase):
    def test_pixel_coordinate_transform(self):
        self.assertEqual(pdf.pixel_box_to_points([0, 10, 100, 210], 200), [0.0, 3.6, 36.0, 75.6])
        self.assertEqual(pdf.pixel_polygon_to_points([[0, 0], [200, 100]], 200), [[0.0, 0.0], [72.0, 36.0]])

    def test_stable_ids(self):
        self.assertEqual(pdf.stable_page_id(7), "page-007")
        self.assertEqual(pdf.stable_block_id(12, 3), "p0012-b0003")

    def test_rotated_page_keeps_displayed_coordinate_declaration(self):
        page = pdf.reconcile_page(native_page(rotation=90), paddle_page([]), 1)
        self.assertEqual(page["rotation"], 90)
        self.assertEqual(page["coordinate_space"]["origin"], "top-left")


class ReconciliationTests(unittest.TestCase):
    def test_reliable_matching_native_text_wins(self):
        page = pdf.reconcile_page(
            native_page([native_block("Clean digital text", [10, 10, 200, 30])]),
            paddle_page([paddle_block("text", "Clean digital text", [10, 10, 200, 30])]), 1,
        )
        block = page["blocks"][0]
        self.assertEqual(block["text"], "Clean digital text")
        self.assertEqual(block["provenance"]["selection"]["selected"], "pymupdf")

    def test_corrupted_native_text_loses(self):
        page = pdf.reconcile_page(
            native_page([native_block("bad\ufffdtext", [10, 10, 200, 30])]),
            paddle_page([paddle_block("text", "Readable OCR", [10, 10, 200, 30])]), 1,
        )
        self.assertEqual(page["blocks"][0]["text"], "Readable OCR")
        self.assertEqual(page["blocks"][0]["provenance"]["selection"]["reason"], "no_reliable_native_text")

    def test_mismatching_native_candidate_is_retained_in_provenance(self):
        page = pdf.reconcile_page(
            native_page([native_block("Completely different", [0, 0, 100, 20])]),
            paddle_page([paddle_block("text", "Expected words", [0, 0, 100, 20])]), 1,
        )
        selection = page["blocks"][0]["provenance"]["selection"]
        self.assertEqual(selection["selected"], "paddleocr-vl")
        self.assertEqual(selection["native_text"], "Completely different")

    def test_unmatched_native_is_preserved_and_duplicates_are_suppressed(self):
        native = native_page([
            native_block("Matched", [0, 0, 100, 20]),
            native_block("Unmatched", [0, 40, 100, 60]),
            native_block("Unmatched", [0, 40, 100, 60]),
        ])
        page = pdf.reconcile_page(native, paddle_page([paddle_block("text", "Matched", [0, 0, 100, 20])]), 1)
        self.assertEqual([block["text"] for block in page["blocks"]], ["Matched", "Unmatched"])

    def test_multi_column_paddle_order_is_preserved(self):
        blocks = [
            paddle_block("text", "right", [320, 10, 500, 40]),
            paddle_block("text", "left", [10, 10, 200, 40]),
            paddle_block("text", "below", [10, 70, 200, 90]),
        ]
        page = pdf.reconcile_page(native_page(), paddle_page(blocks), 1)
        self.assertEqual([item["text"] for item in page["blocks"]], ["right", "left", "below"])

    def test_native_table_grid_wins(self):
        table = {"bbox": [0, 0, 200, 100], "cells": pdf.normalize_grid([["A", "B"], ["1", "2"]]), "rows": 2, "columns": 2}
        page = pdf.reconcile_page(native_page(tables=[table]), paddle_page([paddle_block("table", "<table><tr><td>x</td></tr></table>", [0, 0, 200, 100])]), 1)
        self.assertEqual(page["blocks"][0]["table"]["source"], "pymupdf")
        self.assertEqual(page["blocks"][0]["table"]["cells"][0]["text"], "A")

    def test_paddle_html_table_spans_are_explicit(self):
        cells = pdf.parse_table_markup('<table><tr><th colspan="2">H</th></tr><tr><td>A</td><td>B</td></tr></table>')
        self.assertEqual(cells[0]["column_span"], 2)
        self.assertTrue(cells[0]["header"])

    def test_formula_is_typed_as_latex(self):
        page = pdf.reconcile_page(native_page(), paddle_page([paddle_block("formula", "$x^2$", [0, 0, 50, 20])]), 1)
        self.assertEqual(page["blocks"][0]["formula"]["latex"], "x^2")

    def test_heading_levels_section_paths_and_contains(self):
        native = native_page([
            native_block("Document", [0, 0, 200, 30], 24),
            native_block("Section", [0, 50, 200, 70], 18),
        ])
        paddle = paddle_page([
            paddle_block("title", "Document", [0, 0, 200, 30]),
            paddle_block("heading", "Section", [0, 50, 200, 70]),
            paddle_block("text", "Body", [0, 90, 200, 110]),
        ])
        page = pdf.reconcile_page(native, paddle, 1)
        self.assertEqual(page["blocks"][0]["heading"]["level"], 1)
        self.assertEqual(page["blocks"][1]["heading"]["level"], 2)
        self.assertEqual(page["blocks"][2]["section_path"], ["Document", "Section"])
        self.assertIn("contains", [item["type"] for item in page["relationships"]])

    def test_caption_relationship_and_image_asset(self):
        blocks = [
            paddle_block("figure", "", [0, 0, 100, 80], asset="images/page-001-figure-01.png"),
            paddle_block("caption", "Figure one", [0, 85, 100, 100]),
        ]
        page = pdf.reconcile_page(native_page(), paddle_page(blocks), 1)
        figure = page["blocks"][0]
        self.assertEqual(figure["asset"], "images/page-001-figure-01.png")
        relation = next(item for item in page["relationships"] if item["type"] == "caption_of")
        self.assertEqual(relation["to"], figure["id"])

    def test_link_and_internal_target(self):
        links = [{"from": [0, 0, 100, 20], "uri": "https://example.test"}, {"from": [0, 0, 100, 20], "page": 2}]
        page = pdf.reconcile_page(native_page(links=links), paddle_page([paddle_block("text", "site", [0, 0, 100, 20])]), 1)
        self.assertEqual(page["blocks"][0]["links"][0]["uri"], "https://example.test")
        self.assertIn({"type": "internal_link", "from": "p0001-b0001", "to": "page-003"}, page["relationships"])


class RenderingAndValidationTests(unittest.TestCase):
    def document(self, blocks):
        return {
            "schema_version": 1,
            "document": {"source": {}, "page_count": 1, "extraction_settings": {}},
            "parsers": [],
            "pages": [{"id": "page-001", "number": 1, "width": 1, "height": 1, "rotation": 0, "coordinate_space": {}, "blocks": blocks}],
            "relationships": [],
        }

    def block(self, order, kind="text", text="body", **extra):
        return {"id": pdf.stable_block_id(1, order), "reading_order": order, "type": kind, "text": text, "bbox": [0, 0, 1, 1], "polygon": None, "section_path": [], "links": [], "provenance": {}, **extra}

    def test_markdown_render_pass_covers_semantics(self):
        table = {"rows": 2, "columns": 2, "cells": pdf.normalize_grid([["A", "B"], ["1", "2"]])}
        document = self.document([
            self.block(1, "heading", "Title", heading={"level": 2}),
            self.block(2, "list_item", "item"),
            self.block(3, "table", "", table=table),
            self.block(4, "formula", "", formula={"latex": "x^2"}),
            self.block(5, "image", "plot", asset="images/page-001-figure-01.png"),
            self.block(6, "footnote", "note"),
        ])
        rendered = pdf.render_markdown(document)
        self.assertIn("<!-- page: page-001 -->", rendered)
        self.assertIn('<a id="p0001-b0001"></a>', rendered)
        self.assertIn("## Title", rendered)
        self.assertIn("| A | B |", rendered)
        self.assertIn("$$\nx^2\n$$", rendered)
        self.assertIn("![plot](images/page-001-figure-01.png)", rendered)
        self.assertIn("[^p0001-b0006]: note", rendered)

    def test_html_table_used_for_spans(self):
        table = {"rows": 1, "columns": 2, "cells": [{"row": 0, "column": 0, "row_span": 1, "column_span": 2, "header": True, "text": "H"}]}
        self.assertIn('<th colspan="2">H</th>', "\n".join(pdf.render_table(table)))

    def test_schema_rejects_unstable_ids(self):
        document = self.document([self.block(1)])
        pdf.validate_document(document)
        document["pages"][0]["blocks"][0]["id"] = "random"
        with self.assertRaises(ValueError):
            pdf.validate_document(document)

    def test_raw_paths_are_portable_and_binary_images_are_omitted(self):
        raw = pdf.jsonable({"input_path": "/output/.pdf-ingest-state/render.png", "image": {"path": "/output/x.png", "img": b"pixels"}})
        raw = pdf.portable_raw(raw)
        self.assertEqual(raw["input_path"], ".pdf-ingest-state/render.png")
        self.assertEqual(raw["image"], {"path": "x.png"})

    def test_launcher_contains_offline_sandbox_controls(self):
        launcher = (MODULE_PATH.parent / "pdf-ingest.sh").read_text()
        for flag in ("--pull=never", "--network=none", "--device=nvidia.com/gpu=all", "--cap-drop=all", "--read-only", "--shm-size=2g"):
            self.assertIn(flag, launcher)


class RetryAndDestinationTests(unittest.TestCase):
    IMAGE = "example.invalid/paddle@sha256:" + "a" * 64

    def args(self, source, output, **updates):
        values = {"source": str(source), "output": str(output), "dpi": 200, "min_dpi": 120, "batch_size": 4, "image": self.IMAGE}
        values.update(updates)
        return argparse.Namespace(**values)

    def test_oom_progression_halves_batch_then_dpi(self):
        self.assertEqual(pdf.oom_attempts(4, 200, 120), [(4, 200), (2, 200), (1, 200), (1, 120)])
        self.assertEqual(pdf.oom_attempts(1, 300, 120), [(1, 300), (1, 150), (1, 120)])

    def test_empty_destination_is_initializable_and_unrelated_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            output.mkdir()
            self.assertEqual(pdf.probe(self.args(source, output)), 10)
            (output / "notes.txt").write_text("mine")
            self.assertEqual(pdf.probe(self.args(source, output)), 2)

    def test_matching_resume_and_mismatch_refusal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            state = output / ".pdf-ingest-state"
            state.mkdir(parents=True)
            args = self.args(source, output)
            (state / "manifest.json").write_text(json.dumps({"identity": pdf.identity(args)}))
            self.assertEqual(pdf.probe(args), 10)
            self.assertEqual(pdf.probe(self.args(source, output, dpi=201)), 2)

    def test_complete_matching_result_is_noop(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            (output / "images").mkdir(parents=True)
            (output / "raw").mkdir()
            args = self.args(source, output)
            document = {
                "schema_version": 1,
                "document": {"source": {"sha256": pdf.sha256_file(source)}, "page_count": 0, "extraction_settings": pdf.settings(args)},
                "parsers": [{}, {"image": self.IMAGE}], "pages": [], "relationships": [],
            }
            (output / "source.pdf").write_bytes(source.read_bytes())
            (output / "document.json").write_text(json.dumps(document))
            (output / "document.md").write_text("")
            self.assertEqual(pdf.probe(args), 0)

    def test_partial_finalization_with_matching_state_is_resumable(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            state = output / ".pdf-ingest-state"
            state.mkdir(parents=True)
            args = self.args(source, output)
            (state / "manifest.json").write_text(json.dumps({"identity": pdf.identity(args)}))
            (output / "source.pdf").write_bytes(source.read_bytes())
            (output / "document.json").write_text("partial")
            self.assertEqual(pdf.probe(args), 10)

    def test_compaction_finalizes_exact_layout_and_removes_state(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            state = output / ".pdf-ingest-state"
            (state / "pages").mkdir(parents=True)
            (state / "images").mkdir()
            page = pdf.reconcile_page(
                native_page(),
                paddle_page([paddle_block("text", "Scanned page", [0, 0, 100, 20])]),
                1,
            )
            checkpoint = {
                "native": native_page(),
                "paddle": paddle_page([paddle_block("text", "Scanned page", [0, 0, 100, 20])]),
                "canonical": page,
            }
            pdf.dump_json(state / "pages" / "page-001.json", checkpoint)
            args = self.args(source, output)
            args.source_name = source.name
            pdf.compact(args, "test", 1, state)
            self.assertEqual({item.name for item in output.iterdir()}, {"source.pdf", "document.json", "document.md", "images", "raw"})
            self.assertFalse(state.exists())
            document = json.loads((output / "document.json").read_text())
            pdf.validate_document(document)
            self.assertIn("Scanned page", (output / "document.md").read_text())


if __name__ == "__main__":
    unittest.main()
