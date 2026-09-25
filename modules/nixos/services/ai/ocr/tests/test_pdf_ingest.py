from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "pdf-ingest.py"
ADAPTER_PATH = Path(__file__).parents[1] / "adapters" / "pdf" / "paddleocr-vl" / "adapter.py"


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader
    # Registered before execution so the adapter's `import pdf_ingest` finds
    # this copy of the core.
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


pdf = load_module("pdf_ingest", MODULE_PATH)
paddle = load_module("pdf_ingest_paddleocr_vl", ADAPTER_PATH)


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

    def test_pymupdf_link_geometry_is_converted_before_json_serialization(self):
        class Rect:
            def __iter__(self):
                return iter((10, 20, 30, 40))

            def __str__(self):
                return "Rect(10, 20, 30, 40)"

        class Point:
            x = 50
            y = 60

        link = pdf.serialize_link(
            {"kind": 1, "from": Rect(), "to": Point(), "uri": "https://example.test"},
            lambda value: list(value),
        )
        self.assertEqual(link["from"], [10, 20, 30, 40])
        self.assertEqual(link["to"], [50.0, 60.0])


class PaddleAdapterTests(unittest.TestCase):
    def test_dict_subclass_uses_public_json_block_representation(self):
        class PaddleBlock:
            def __str__(self):
                return "label:\ttext\nbbox:\t[0, 0, 100, 20]\ncontent:\tOCR text"

        class PaddleResult(dict):
            @property
            def json(self):
                return {
                    "res": {
                        "parsing_res_list": [
                            {
                                "block_label": "text",
                                "block_content": "OCR text",
                                "block_bbox": [0, 0, 100, 20],
                                "block_id": 7,
                            }
                        ]
                    }
                }

        class Pipeline:
            def predict(self, **kwargs):
                return [PaddleResult(parsing_res_list=[PaddleBlock()])]

        adapter = paddle.PaddleOCRVLAdapter.__new__(paddle.PaddleOCRVLAdapter)
        adapter.pipeline = Pipeline()
        adapter.batch_size = 1
        page = adapter.parse_page(Path("render.png"), 200)

        self.assertEqual(page["blocks"][0]["text"], "OCR text")
        self.assertEqual(page["blocks"][0]["bbox"], [0.0, 0.0, 36.0, 7.2])
        self.assertEqual(page["blocks"][0]["parser_block_id"], 7)


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

    def test_provenance_names_follow_layout_adapter(self):
        native = native_page([native_block("Different words", [0, 0, 100, 20])])
        layout = paddle_page([paddle_block("text", "Expected", [0, 0, 100, 20]), paddle_block("table", "", [0, 50, 100, 80])])
        # Schema v1 names from before the adapter split stay the default.
        page = pdf.reconcile_page(native, layout, 1)
        self.assertEqual(page["blocks"][0]["provenance"]["selection"]["selected"], "paddleocr-vl")
        self.assertEqual(page["blocks"][0]["provenance"]["raw"], {"paddleocr_vl": "/pages/0/result/parsing_res_list/0", "pymupdf": ["/pages/0/blocks/0"]})
        self.assertEqual(page["blocks"][1]["table"]["source"], "paddleocr-vl")
        self.assertEqual(page, pdf.reconcile_page(native, layout, 1, "paddleocr-vl"))

        page = pdf.reconcile_page(native, layout, 1, "other-parser")
        self.assertEqual(page["blocks"][0]["provenance"]["selection"]["selected"], "other-parser")
        self.assertIn("other_parser", page["blocks"][0]["provenance"]["raw"])
        self.assertEqual(page["blocks"][1]["table"]["source"], "other-parser")

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

    def test_overlapping_figure_blocks_claim_embedded_image_once(self):
        native = native_page(images=[{"xref": 1, "asset": "images/page-001-figure-01.jpeg", "bbox": [0, 0, 100, 80], "width": 10, "height": 10, "encoding": "jpeg"}])
        paddle = paddle_page([paddle_block("figure", "", [0, 0, 100, 80]), paddle_block("figure", "", [5, 5, 105, 85])])
        pdf.attach_rendered_assets(Path("unused.png"), paddle, native, Path("unused-assets"), 1, 200)
        self.assertEqual(paddle["blocks"][0]["asset"], "images/page-001-figure-01.jpeg")
        self.assertNotIn("asset", paddle["blocks"][1])

    def test_split_table_merges_across_pages_and_renumbers_blocks(self):
        def table_page(rows, number, extra_blocks=None):
            table = {"bbox": [0, 0, 200, 100], "cells": pdf.normalize_grid(rows), "rows": len(rows), "columns": 2}
            return pdf.reconcile_page(native_page(tables=[table]), paddle_page([paddle_block("table", "", [0, 0, 200, 100])] + (extra_blocks or [])), number)

        pages = [
            table_page([["Project", "Unit"], ["Laser", "nm"]], 1),
            table_page([["Light", "lx"], ["Speed", "Hz"]], 2, [paddle_block("text", "Continued", [0, 120, 200, 140])]),
        ]
        relationships = pdf.finalize_document_structure(pages)
        merged = pages[0]["blocks"][-1]["table"]
        self.assertEqual(merged["rows"], 4)
        self.assertEqual([cell["text"] for cell in merged["cells"] if cell["row"] == 2], ["Light", "lx"])
        self.assertFalse(any(cell["header"] for cell in merged["cells"] if cell["row"] >= 2))
        self.assertEqual(pages[1]["blocks"][0]["id"], "p0002-b0001")
        self.assertEqual(pages[1]["blocks"][0]["text"], "Continued")
        known = {block["id"] for page in pages for block in page["blocks"]}
        for item in relationships:
            self.assertNotIn("p0002-b0002", (item["from"], item["to"]))
            if item["from"].startswith("p"):
                self.assertIn(item["from"], known)

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
        self.assertIn("<!-- a: p0001-b0001 -->", rendered)
        self.assertIn("## Title", rendered)
        self.assertIn("| A | B |", rendered)
        self.assertIn("$$\nx^2\n$$", rendered)
        self.assertIn("![plot](images/page-001-figure-01.png)", rendered)
        self.assertIn("[^p0001-b0006]: note", rendered)

    def test_html_table_used_for_spans(self):
        table = {"rows": 1, "columns": 2, "cells": [{"row": 0, "column": 0, "row_span": 1, "column_span": 2, "header": True, "text": "H"}]}
        self.assertIn('<th colspan="2">H</th>', "\n".join(pdf.render_table(table)))

    def test_multiline_cells_use_configurable_line_break(self):
        table = {"rows": 2, "columns": 1, "cells": pdf.normalize_grid([["Minimum\nvalue"], ["Typical\nvalue"]])}
        self.assertIn("| Minimum<br>value |", "\n".join(pdf.render_table(table)))
        spanned = {"rows": 1, "columns": 2, "cells": [{"row": 0, "column": 0, "row_span": 1, "column_span": 2, "header": False, "text": "A & B\nC"}]}
        self.assertIn('<td colspan="2">A &amp; B<br>C</td>', "\n".join(pdf.render_table(spanned)))

    def test_image_alt_text_is_sanitized(self):
        document = self.document([self.block(1, "figure", "2 | **Focus Camera**\nLaser", asset="images/page-001-figure-01.jpeg")])
        self.assertIn("![2 Focus Camera Laser](images/page-001-figure-01.jpeg)", pdf.render_markdown(document))

    def test_text_inside_embedded_image_renders_as_code_block(self):
        document = self.document([
            self.block(1, "heading", "user@host: ~$ ls\ntotal 0", heading={"level": 3}, bbox=[0.05, 0.05, 0.45, 0.45]),
            self.block(2, "image", "", asset="images/page-001-figure-01.png", bbox=[0, 0, 0.5, 0.5]),
        ])
        rendered = pdf.render_markdown(document)
        self.assertIn("```\nuser@host: ~$ ls\ntotal 0\n```", rendered)
        self.assertNotIn("###", rendered)

    def test_full_page_scan_text_is_not_fenced(self):
        document = self.document([
            self.block(1, "text", "scanned body text"),
            self.block(2, "image", "", asset="images/page-001-figure-01.png", bbox=[0, 0, 1, 1]),
        ])
        rendered = pdf.render_markdown(document)
        self.assertIn("scanned body text", rendered)
        self.assertNotIn("```", rendered)

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
        # The NixOS module concatenates the prelude in front of the launcher.
        prelude = (MODULE_PATH.parent / "pdf-ingest-image.sh").read_text()
        launcher = (MODULE_PATH.parent / "pdf-ingest.sh").read_text()
        for flag in (
            '"--device=$pdf_ingest_device_spec"',
            "--group-add=keep-groups",
            "--env=MIOPEN_USER_DB_PATH=/tmp/miopen/db",
            "--env=MIOPEN_CUSTOM_CACHE_DIR=/tmp/miopen/cache",
            "--env=HF_HOME=/tmp/hf",
            "podman build --pull=missing",
        ):
            self.assertIn(flag, prelude)
        self.assertNotIn("nvidia.com/gpu=all", prelude)
        for flag in (
            "--pull=never",
            "--network=none",
            "--http-proxy=false",
            "--ipc=private",
            "--pid=private",
            "--uts=private",
            "--cgroupns=private",
            '"${gpu_args[@]}"',
            "--user=0:0",
            "--cap-drop=all",
            "--read-only",
            '--shm-size="$PDF_INGEST_SHM_SIZE"',
            '"--tmpfs=/tmp:rw,nosuid,nodev,size=$PDF_INGEST_TMP_SIZE"',
            "--env=HF_HUB_OFFLINE=1",
            '"--env=PDF_INGEST_DTYPE=$PDF_INGEST_DTYPE"',
            "--env=XDG_CACHE_HOME=/tmp/cache",
            '"--mount=type=bind,source=$source_pdf,target=/input/source.pdf,readonly"',
            '"--mount=type=bind,source=$output_dir,target=/output,rw"',
            '"--mount=type=bind,source=$PDF_INGEST_PIPELINE,target=/opt/pdf-ingest/pdf-ingest.py,readonly"',
            '"--mount=type=bind,source=$PDF_INGEST_ADAPTER_MODULE,target=/opt/pdf-ingest/adapter.py,readonly"',
            '"--env=PDF_INGEST_ADAPTER=$PDF_INGEST_ADAPTER"',
            'container_args+=("--env=$container_env_entry")',
        ):
            self.assertIn(flag, launcher)
        self.assertNotIn('"--volume=$source_pdf:/input/source.pdf:ro"', launcher)
        for flag in ("--clearenv", "--unshare-all", "--ro-bind /nix/store /nix/store", "--ro-bind \"$source_pdf\" /input/source.pdf"):
            self.assertIn(flag, launcher)
        self.assertIn('"$PDF_INGEST_PIPELINE" prepare', launcher)
        self.assertIn("pdf-ingest.py infer", launcher)
        self.assertNotIn("--device=nvidia.com/gpu=all", launcher)
        # Adapter-specific environment comes from the NixOS adapter module.
        self.assertNotIn("PADDLE", launcher)
        self.assertLess(launcher.index("ensure_image\n"), launcher.index("pdf-ingest.py infer"))

    def test_oom_detection_covers_cuda_and_rocm_messages(self):
        for message in (
            "ResourceExhaustedError: Out of memory error on GPU 0",
            "CUDA out of memory. Tried to allocate 20.00 MiB",
            "HIP out of memory. Tried to allocate 512.00 MiB (GPU 0; hipErrorOutOfMemory)",
            "HSA_STATUS_ERROR_OUT_OF_RESOURCES: out of memory",
        ):
            self.assertTrue(pdf.is_cuda_oom(RuntimeError(message)), message)
        self.assertFalse(pdf.is_cuda_oom(RuntimeError("out of memory")))
        self.assertFalse(pdf.is_cuda_oom(RuntimeError("CUDA error: an illegal memory access")))

    def test_adapter_kwargs_follow_engine_environment(self):
        with mock.patch.dict("os.environ", {"PDF_INGEST_ENGINE": "paddle"}):
            kwargs = paddle.PaddleOCRVLAdapter.pipeline_kwargs()
        self.assertEqual(kwargs["precision"], "fp16")
        self.assertEqual(kwargs["device"], "gpu:0")
        self.assertNotIn("engine", kwargs)
        self.assertNotIn("engine_config", kwargs)

        with mock.patch.dict("os.environ", {"PDF_INGEST_ENGINE": "transformers", "PDF_INGEST_DTYPE": "float32"}):
            kwargs = paddle.PaddleOCRVLAdapter.pipeline_kwargs()
        self.assertEqual(kwargs["engine"], "transformers")
        self.assertEqual(kwargs["engine_config"], {"dtype": "float32"})
        self.assertEqual(kwargs["device"], "gpu:0")
        self.assertNotIn("precision", kwargs)

    def test_adapter_constructs_pipeline_from_kwargs(self):
        import sys
        import types

        fake = types.ModuleType("paddleocr")
        fake.PaddleOCRVL = mock.Mock(return_value="pipeline")
        with mock.patch.dict(sys.modules, {"paddleocr": fake}), mock.patch.dict("os.environ", {"PDF_INGEST_ENGINE": "transformers", "PDF_INGEST_DTYPE": "float16"}):
            adapter = paddle.PaddleOCRVLAdapter(2)
        self.assertEqual(adapter.pipeline, "pipeline")
        self.assertEqual(adapter.batch_size, 2)
        called = fake.PaddleOCRVL.call_args.kwargs
        self.assertEqual(called["engine"], "transformers")
        self.assertEqual(called["engine_config"], {"dtype": "float16"})
        self.assertEqual(called["vl_rec_backend"], "native")

    def test_bundled_cache_default_comes_from_environment(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundled = root / "rocm-bundled"
            cache = root / "runtime"
            (bundled / "official_models").mkdir(parents=True)
            with mock.patch.dict("os.environ", {"PADDLE_PDX_CACHE_HOME": str(cache), "PDF_INGEST_BUNDLED_CACHE": str(bundled)}):
                paddle.initialize_paddle_cache()
            self.assertEqual((cache / "official_models").resolve(), bundled / "official_models")
            self.assertFalse((cache / "fonts").exists())

    def test_writable_paddle_cache_links_bundled_resources(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundled = root / "bundled"
            cache = root / "runtime"
            (bundled / "official_models").mkdir(parents=True)
            (bundled / "fonts").mkdir()
            with mock.patch.dict("os.environ", {"PADDLE_PDX_CACHE_HOME": str(cache)}):
                paddle.initialize_paddle_cache(bundled)
            self.assertEqual((cache / "official_models").resolve(), bundled / "official_models")
            self.assertEqual((cache / "fonts").resolve(), bundled / "fonts")
            (cache / "func_ret").mkdir()
            (cache / "temp").mkdir()


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
            # Checkpoints from before the adapter split store the layout
            # result under "paddle"; an interrupted run must still compact.
            checkpoint = {
                "native": native_page(),
                "paddle": paddle_page([paddle_block("text", "Scanned page", [0, 0, 100, 20])]),
                "canonical": page,
            }
            pdf.dump_json(state / "pages" / "page-001.json", checkpoint)
            args = self.args(source, output)
            args.source_name = source.name
            with mock.patch.dict("os.environ", {"PDF_INGEST_ENGINE": "transformers", "PDF_INGEST_DTYPE": "float32", "PDF_INGEST_ACCELERATOR": "rocm"}), mock.patch.object(paddle, "paddleocr_version", return_value="3.7.0"):
                pdf.compact(args, "test", 1, state, paddle.PaddleOCRVLAdapter)
            self.assertEqual({item.name for item in output.iterdir()}, {"source.pdf", "document.json", "document.md", "images", "raw"})
            self.assertEqual({item.name for item in (output / "raw").iterdir()}, {"pymupdf.json", "paddleocr-vl.json"})
            self.assertFalse(state.exists())
            document = json.loads((output / "document.json").read_text())
            pdf.validate_document(document)
            self.assertEqual(document["parsers"][1], {
                "adapter": "paddleocr-vl", "package_version": "3.7.0", "model": "PaddleOCR-VL-1.6", "image": self.IMAGE,
                "accelerator": "rocm", "engine": "transformers", "dtype": "float32", "device": "gpu:0",
                "settings": {"all_pages": True, "layout_detection": True, "chart_recognition": True, "orientation": False, "unwarping": False, "concurrency": 1},
            })
            raw = json.loads((output / "raw" / "paddleocr-vl.json").read_text())
            self.assertEqual((raw["adapter"], raw["model"], raw["pages"][0]["dpi"]), ("paddleocr-vl", "PaddleOCR-VL-1.6", 200))
            self.assertIn("Scanned page", (output / "document.md").read_text())

    def test_layout_adapter_is_loaded_from_module_path(self):
        with mock.patch.dict("os.environ", {"PDF_INGEST_ADAPTER_MODULE": str(ADAPTER_PATH)}):
            adapter = pdf.load_layout_adapter()
        self.assertEqual((adapter.name, adapter.model), ("paddleocr-vl", "PaddleOCR-VL-1.6"))
        self.assertTrue(issubclass(adapter, pdf.ParserAdapter))

    def test_inference_phase_does_not_require_pymupdf(self):
        class FakePaddle(pdf.ParserAdapter):
            name = "paddleocr-vl"
            model = "fake"

            def __init__(self, batch_size):
                self.batch_size = batch_size

            def parse_page(self, image_path, dpi):
                return paddle_page([paddle_block("text", "OCR only", [0, 0, 100, 20])])

            def clear_cache(self):
                pass

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "input.pdf"
            source.write_bytes(b"%PDF-1.7\n")
            output = root / "out"
            state = output / ".pdf-ingest-state"
            for directory in (state / "pages", state / "native", state / "renders", state / "images"):
                directory.mkdir(parents=True, exist_ok=True)
            args = self.args(source, output, batch_size=1)
            args.source_name = source.name
            pdf.dump_json(state / "manifest.json", {"identity": pdf.identity(args)})
            pdf.dump_json(state / "native" / "metadata.json", {"page_count": 1, "package_version": "test"})
            pdf.dump_json(state / "native" / "page-001.json", native_page())
            (state / "renders" / "page-001-200.png").write_bytes(b"unused by fake adapter")
            with mock.patch.object(pdf, "load_layout_adapter", return_value=FakePaddle), mock.patch.object(
                pdf, "PyMuPDFAdapter", side_effect=AssertionError("container inference imported PyMuPDF")
            ):
                self.assertEqual(pdf.infer(args), 0)
            self.assertIn("OCR only", (output / "document.md").read_text())


if __name__ == "__main__":
    unittest.main()
