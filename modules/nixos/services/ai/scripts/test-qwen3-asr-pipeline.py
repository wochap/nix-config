#!/usr/bin/env python3

import importlib.util
import pathlib
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

    def test_speaker_assignment_marks_non_overlap_unknown(self):
        tokens = [{"start": 3.0, "end": 3.2}]
        regions = [{"start": 0.0, "end": 1.0, "speaker": "SPEAKER_00"}]
        PIPELINE.assign_speakers(tokens, regions)
        self.assertEqual(tokens[0]["speaker"], "UNKNOWN")

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


if __name__ == "__main__":
    unittest.main()
