# Qwen3-ASR-1.7B

Enable on-demand transcription with the Transformers backend:

```nix
_custom.services.ai = {
  enable = true;
  enableNvidia = true;
  enableQwen3Asr = true;
};
```

Each command starts Qwen's official CUDA container, runs Transformers inference
on the NVIDIA GPU, and removes the container afterward. VRAM is therefore
released when transcription finishes; there is no persistent API server.

The pinned image is about 14 GB and the model download is about 4.7 GB. Rootless
Podman stores the image in the user's container storage and model files persist
in `~/.cache/qwen3-asr`.

Transcribe a local audio file:

```console
$ qwen3-asr-transcribe recording.wav
$ qwen3-asr-transcribe --language English recording.mp3
$ qwen3-asr-transcribe --language Spanish part-*.wav
```

For a video, the helper extracts mono 16 kHz audio with FFmpeg, transcribes it,
adds token timestamps with Qwen3-ForcedAligner-0.6B, and assigns speakers with
the local pyannote Community-1 pipeline. Before the first run, accept the model
conditions at <https://huggingface.co/pyannote/speaker-diarization-community-1>
and configure `personal-huggingface-local-read-token` in
`secrets-sops/personal.yaml`. An explicitly exported `HF_TOKEN` overrides the
configured secret:

```console
$ export HF_TOKEN=hf_...
$ qwen3-asr-video video.mp4
$ qwen3-asr-video --language English --num-speakers 2 video.mkv
$ qwen3-asr-video --language es --min-speakers 2 --max-speakers 5 video.mkv
```

The command writes `video.txt` and `video.json` by default. The text file has
one timestamped speaker turn per line, while the versioned JSON file retains
ASR chunks, detected languages, aligned tokens, exclusive diarization regions,
and merged turns. Use `--output` and `--json-output` to choose other paths.

The first invocation also builds a local inference image from Qwen's pinned
official image and installs the pinned pyannote runtime. Later runs reuse that
image and the model cache in `~/.cache/qwen3-asr`.

Long audio is transcribed in four-minute chunks to keep inference within an
8 GB GPU. Override the chunk duration if needed with
`QWEN3_ASR_CHUNK_SECONDS`; smaller values use less VRAM without changing the
model or audio quality:

```console
$ QWEN3_ASR_CHUNK_SECONDS=180 qwen3-asr-video long-video.mp4
```

The ASR, forced aligner, and diarization models are loaded sequentially rather
than simultaneously so the pipeline remains usable on an 8 GB RTX 4060.

The container receives only the temporary extracted audio read-only, the
inference script read-only, and the dedicated model cache. It does not receive
the containing video directory, the home directory, SSH/GPG keys, or a Podman
socket. No port is opened. After the image and all three models have been
downloaded once, set `QWEN3_ASR_OFFLINE=1` to disable container networking:

```console
$ QWEN3_ASR_OFFLINE=1 qwen3-asr-video video.mp4
```
