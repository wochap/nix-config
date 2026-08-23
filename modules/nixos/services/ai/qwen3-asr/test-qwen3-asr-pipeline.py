#!/usr/bin/env python3

import importlib.util
import contextlib
import io
import json
import pathlib
import tempfile
import types
import unittest


SCRIPT = pathlib.Path(__file__).with_name("qwen3-asr-pipeline.py")
SPEC = importlib.util.spec_from_file_location("qwen3_asr_pipeline", SCRIPT)
PIPELINE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(PIPELINE)


class PipelineTest(unittest.TestCase):
    def test_language_aliases(self):
        self.assertEqual(PIPELINE.canonical_language("es"), "Spanish")
        self.assertEqual(PIPELINE.canonical_language("ENGLISH"), "English")
        self.assertIsNone(PIPELINE.canonical_language(None))

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
            "schema_version": 1,
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

    def test_validation_rejects_non_finite_timestamp(self):
        document = {
            "schema_version": 1,
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


if __name__ == "__main__":
    unittest.main()
