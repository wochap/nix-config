#!/usr/bin/env python3

import importlib.util
import contextlib
import io
import json
import pathlib
import tempfile
import types
import unittest
import wave
from unittest import mock


SCRIPT = pathlib.Path(__file__).parents[1] / "pipeline.py"
SPEC = importlib.util.spec_from_file_location("asr_pipeline", SCRIPT)
PIPELINE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(PIPELINE)


class PipelineTest(unittest.TestCase):
    def test_language_normalizes_to_iso_code(self):
        self.assertEqual(PIPELINE.canonical_language("es"), "es")
        self.assertEqual(PIPELINE.canonical_language("ENGLISH"), "en")
        self.assertEqual(PIPELINE.canonical_language(" Cantonese "), "yue")
        self.assertIsNone(PIPELINE.canonical_language(None))

    def test_language_rejects_unknown_input(self):
        with self.assertRaisesRegex(ValueError, "unknown language"):
            PIPELINE.canonical_language("Klingon")

    def test_language_keeps_unknown_detected_value(self):
        self.assertEqual(PIPELINE.canonical_language("Klingon", strict=False), "klingon")

    def test_display_units_preserves_punctuation(self):
        self.assertEqual(
            PIPELINE.display_units("Hey, did you finish the PR?", ["Hey", "did", "you", "finish", "the", "PR"]),
            ["Hey, ", "did ", "you ", "finish ", "the ", "PR?"],
        )

    def test_fallback_does_not_add_spaces_between_cjk_characters(self):
        self.assertEqual(PIPELINE.fallback_display_units(["你", "好"]), ["你", "好"])

    def test_speaker_assignment_uses_greatest_overlap(self):
        tokens = [{"start": 0.8, "end": 1.2}]
        regions = [
            {"start": 0.0, "end": 0.9, "speaker": "SPEAKER_00"},
            {"start": 0.9, "end": 2.0, "speaker": "SPEAKER_01"},
        ]
        PIPELINE.assign_speakers(tokens, regions)
        self.assertEqual(tokens[0]["speaker"], "SPEAKER_01")

    def test_zero_duration_token_inside_region(self):
        tokens = [{"start": 0.5, "end": 0.5}]
        regions = [{"start": 0.0, "end": 1.0, "speaker": "SPEAKER_00"}]
        PIPELINE.assign_speakers(tokens, regions)
        self.assertEqual(tokens[0]["speaker"], "SPEAKER_00")

    def test_small_gap_between_regions_of_same_speaker(self):
        tokens = [{"start": 1.1, "end": 1.1}]
        regions = [
            {"start": 0.0, "end": 1.0, "speaker": "SPEAKER_00"},
            {"start": 1.2, "end": 2.0, "speaker": "SPEAKER_00"},
        ]
        PIPELINE.assign_speakers(tokens, regions)
        self.assertEqual(tokens[0]["speaker"], "SPEAKER_00")

    def test_speaker_assignment_marks_non_overlap_unknown(self):
        tokens = [{"start": 3.0, "end": 3.2}]
        regions = [{"start": 0.0, "end": 1.0, "speaker": "SPEAKER_00"}]
        PIPELINE.assign_speakers(tokens, regions)
        self.assertEqual(tokens[0]["speaker"], "UNKNOWN")

    def test_smooths_unknown_sequence_between_same_speaker(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00"},
            {"start": 0.3, "end": 0.3, "speaker": "UNKNOWN"},
            {"start": 0.4, "end": 0.5, "speaker": "UNKNOWN"},
            {"start": 0.6, "end": 0.8, "speaker": "SPEAKER_00"},
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        self.assertEqual([token["speaker"] for token in tokens], ["SPEAKER_00"] * 4)

    def test_gap_between_different_speakers_uses_proximity(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00"},
            {"start": 0.7, "end": 0.7, "speaker": "UNKNOWN"},
            {"start": 0.8, "end": 1.0, "speaker": "SPEAKER_01"},
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        self.assertEqual(tokens[1]["speaker"], "SPEAKER_01")

    def test_gap_tie_between_different_speakers_prefers_previous(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00"},
            {"start": 0.5, "end": 0.5, "speaker": "UNKNOWN"},
            {"start": 0.8, "end": 1.0, "speaker": "SPEAKER_01"},
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        self.assertEqual(tokens[1]["speaker"], "SPEAKER_00")

    def test_isolated_unknown_stays_unknown(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00"},
            {"start": 1.0, "end": 1.0, "speaker": "UNKNOWN"},
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        self.assertEqual(tokens[1]["speaker"], "UNKNOWN")

    def test_long_gap_between_same_speaker_is_not_hidden(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00"},
            {"start": 2.0, "end": 2.0, "speaker": "UNKNOWN"},
            {"start": 4.0, "end": 4.2, "speaker": "SPEAKER_00"},
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        self.assertEqual(tokens[1]["speaker"], "UNKNOWN")

    def test_interleaved_regression_builds_one_turn(self):
        words = ["todos lados por ejemplo ", "en ", "Chipre ", "creo que es de ", "veinte ", "mil ", "así que depende un poco del país"]
        starts = [1196.80, 1197.68, 1197.76, 1198.24, 1198.24, 1199.28, 1200.48]
        ends = [1197.60, 1197.76, 1198.20, 1198.24, 1199.20, 1199.60, 1201.00]
        speakers = ["SPEAKER_01", "UNKNOWN", "SPEAKER_01", "UNKNOWN", "SPEAKER_01", "UNKNOWN", "SPEAKER_01"]
        tokens = [
            {"start": start, "end": end, "speaker": speaker, "text": word.strip(), "display": word}
            for start, end, speaker, word in zip(starts, ends, speakers, words)
        ]
        PIPELINE.smooth_unknown_speakers(tokens)
        turns = PIPELINE.build_turns(tokens)
        self.assertEqual(len(turns), 1)
        self.assertEqual(turns[0]["speaker"], "SPEAKER_01")
        self.assertEqual(turns[0]["text"], "".join(words).strip())

    def test_turns_split_on_speaker_and_long_gap(self):
        tokens = [
            {"start": 0.0, "end": 0.2, "speaker": "SPEAKER_00", "text": "Hello", "display": "Hello "},
            {"start": 0.3, "end": 0.5, "speaker": "SPEAKER_00", "text": "there", "display": "there."},
            {"start": 0.6, "end": 0.8, "speaker": "SPEAKER_01", "text": "Hi", "display": "Hi."},
            {"start": 2.0, "end": 2.2, "speaker": "SPEAKER_01", "text": "Again", "display": "Again."},
        ]
        turns = PIPELINE.build_turns(tokens)
        self.assertEqual([turn["text"] for turn in turns], ["Hello there.", "Hi.", "Again."])

    def test_timestamp_format(self):
        self.assertEqual(PIPELINE.transcript_timestamp(0.52), "00:00.52")
        self.assertEqual(PIPELINE.transcript_timestamp(3661.25), "01:01:01.25")

    def test_chunk_plan_prefers_latest_nearby_silence(self):
        boundaries = PIPELINE.plan_chunk_boundaries(
            duration=700.0,
            silences=[205.0, 235.0, 450.0, 472.0],
            max_seconds=240.0,
            search_seconds=30.0,
        )
        self.assertEqual(boundaries, [235.0, 472.0])
        lengths = [boundaries[0], boundaries[1] - boundaries[0], 700.0 - boundaries[1]]
        self.assertTrue(all(length <= 240.0 for length in lengths))

    def test_chunk_plan_avoids_tiny_final_chunk(self):
        self.assertEqual(
            PIPELINE.plan_chunk_boundaries(241.0, [], max_seconds=240.0),
            [211.0],
        )

    def test_chunk_plan_uses_hard_limit_without_silence(self):
        boundaries = PIPELINE.plan_chunk_boundaries(600.0, [], max_seconds=240.0)
        self.assertEqual(boundaries, [240.0, 480.0])

    def test_validation_reports_quality_signals(self):
        document = {
            "schema_version": 2,
            "source": {"duration": 2.0},
            "chunks": [{"start": 0.0, "end": 2.0, "text": ""}],
            "tokens": [{"start": 0.1, "end": 0.2, "speaker": "UNKNOWN"}],
            "exclusive_diarization": [
                {"start": 0.1, "end": 0.15, "speaker": "SPEAKER_00"}
            ],
            "turns": [{"start": 0.1, "end": 0.2}],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "result.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                PIPELINE.validate(types.SimpleNamespace(input=str(path)))
        self.assertIn("1 chunks (1 empty)", stderr.getvalue())
        self.assertIn("1 tokens (1 UNKNOWN)", stderr.getvalue())
        self.assertIn("1 under 100 ms", stderr.getvalue())

    def test_runtime_defaults_to_cuda_bfloat16(self):
        self.assertEqual(PIPELINE.resolve_runtime({}), ("cuda:0", "bfloat16"))

    def test_runtime_reads_device_and_dtype_from_env(self):
        self.assertEqual(
            PIPELINE.resolve_runtime({"ASR_DEVICE": "cuda:1", "ASR_DTYPE": "float16"}),
            ("cuda:1", "float16"),
        )

    def test_diarization_progress_logs_stage_and_quarters(self):
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            PIPELINE.diarization_progress("segmentation", None)
            for completed in range(0, 9):
                PIPELINE.diarization_progress("segmentation", None, total=8, completed=completed)
        lines = stderr.getvalue().splitlines()
        self.assertEqual(len(lines), 6)
        self.assertIn("Diarization stage segmentation", lines[0])
        self.assertTrue(lines[-1].endswith("Diarization segmentation: 8/8"))

    def test_runtime_rejects_unknown_dtype(self):
        with self.assertRaisesRegex(RuntimeError, "unsupported"):
            PIPELINE.resolve_runtime({"ASR_DTYPE": "float8"})

    def test_validation_rejects_non_finite_timestamp(self):
        document = {
            "schema_version": 2,
            "source": {"duration": 2.0},
            "chunks": [{"start": 0.0, "end": float("nan"), "text": "hello"}],
            "tokens": [],
            "exclusive_diarization": [],
            "turns": [],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "result.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "not finite"):
                PIPELINE.validate(types.SimpleNamespace(input=str(path)))

STUB_ADAPTER = """
from types import SimpleNamespace


class Transcriber:
    def __init__(self, models):
        assert models["asr"]["repo"] == "stub/asr"

    def transcribe(self, paths, language):
        return [SimpleNamespace(text="Hello there.", language="English") for _ in paths]


class Aligner:
    def align(self, path, text, language):
        return [SimpleNamespace(text="Hello", start=0.1, end=0.4),
                SimpleNamespace(text="there", start=0.5, end=0.9)]


def load_transcriber(device, dtype, batch_size, models):
    return Transcriber(models)


def load_aligner(device, dtype, models):
    assert models["aligner"]["revision"] == "b"
    return Aligner()
"""


def write_silence(path, seconds):
    with wave.open(str(path), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(16000)
        audio.writeframes(b"\0\0" * int(16000 * seconds))


STUB_MODELS = {
    "asr": {"repo": "stub/asr", "revision": "a", "role": "transcriber"},
    "aligner": {"repo": "stub/aligner", "revision": "b", "role": "aligner"},
    "diarizer": {"repo": "stub/diarizer", "revision": "c", "role": "diarizer"},
}


class AdapterSeamTest(unittest.TestCase):
    def run_infer(self, no_diarize=False):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            audio_dir = root / "input"
            audio_dir.mkdir()
            write_silence(audio_dir / "full.wav", 2.0)
            write_silence(audio_dir / "chunk-00000.wav", 1.0)
            write_silence(audio_dir / "chunk-00001.wav", 1.0)
            adapter = root / "adapter.py"
            adapter.write_text(STUB_ADAPTER, encoding="utf-8")
            regions = [
                {"start": 0.0, "end": 1.0, "speaker": "SPEAKER_00"},
                {"start": 1.0, "end": 2.0, "speaker": "SPEAKER_01"},
            ]
            args = types.SimpleNamespace(
                audio_dir=str(audio_dir),
                state_dir=str(root / "state"),
                source_name="stub.mp4",
                source_id="stub",
                language=None,
                num_speakers=None,
                min_speakers=None,
                max_speakers=None,
                no_diarize=no_diarize,
            )
            stdout = io.StringIO()
            with (
                mock.patch.dict("os.environ", {"ASR_MODELS": json.dumps(STUB_MODELS)}, clear=True),
                mock.patch.multiple(
                    PIPELINE,
                    ADAPTER="stub",
                    ADAPTER_MODULE=str(adapter),
                    CACHE_DIR=root / "cache",
                    diarize=lambda *_: regions,
                ),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(io.StringIO()),
            ):
                PIPELINE.infer(args)
            markers = sorted(path.name for path in (root / "cache" / "asr-verified").iterdir())
        return json.loads(stdout.getvalue()), markers

    def test_infer_runs_with_stub_adapter(self):
        document, markers = self.run_infer()
        self.assertEqual(document["schema_version"], 2)
        self.assertEqual(document["adapter"], "stub")
        self.assertTrue(document["diarized"])
        self.assertEqual(sorted(document["models"]), ["aligner", "asr", "diarizer"])
        self.assertEqual(document["detected_languages"], ["en"])
        self.assertEqual([token["start"] for token in document["tokens"]], [0.1, 0.5, 1.1, 1.5])
        self.assertEqual(
            [(turn["speaker"], turn["text"]) for turn in document["turns"]],
            [("SPEAKER_00", "Hello there."), ("SPEAKER_01", "Hello there.")],
        )
        # The diarizer is stubbed out, so only the adapter's models load.
        self.assertEqual(markers, ["stub--aligner@b", "stub--asr@a"])

    def test_infer_without_diarization_emits_chunk_turns(self):
        document, markers = self.run_infer(no_diarize=True)
        self.assertFalse(document["diarized"])
        self.assertEqual(sorted(document["models"]), ["asr"])
        self.assertEqual(document["tokens"], [])
        self.assertEqual(document["exclusive_diarization"], [])
        self.assertEqual(
            [(turn["start"], turn["speaker"], turn["text"]) for turn in document["turns"]],
            [(0.0, None, "Hello there."), (1.0, None, "Hello there.")],
        )
        self.assertEqual(markers, ["stub--asr@a"])

    def test_models_cached_needs_every_marker_for_the_roles(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = pathlib.Path(directory)

            def cached(roles):
                args = types.SimpleNamespace(cache_dir=str(cache), roles=roles)
                with mock.patch.dict("os.environ", {"ASR_MODELS": json.dumps(STUB_MODELS)}, clear=True):
                    with self.assertRaises(SystemExit) as exit_:
                        PIPELINE.models_cached(args)
                return exit_.exception.code == 0

            self.assertFalse(cached("transcriber"))
            with mock.patch.object(PIPELINE, "CACHE_DIR", cache):
                PIPELINE.mark_verified({"asr": STUB_MODELS["asr"]})
            self.assertTrue(cached("transcriber"))
            self.assertFalse(cached("transcriber,aligner,diarizer"))

    def test_load_models_rejects_unknown_role(self):
        with self.assertRaisesRegex(RuntimeError, "invalid ASR_MODELS entry"):
            PIPELINE.load_models({"ASR_MODELS": json.dumps({"x": {"repo": "a/b", "revision": "c", "role": "other"}})})

    def test_render_omits_missing_speaker(self):
        document = {"schema_version": 2, "turns": [{"start": 1.0, "speaker": None, "text": "hi"}]}
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "result.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                PIPELINE.render(types.SimpleNamespace(input=str(path)))
        self.assertEqual(stdout.getvalue(), "[00:01.00] hi\n")


if __name__ == "__main__":
    unittest.main()
