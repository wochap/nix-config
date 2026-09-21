# Qwen3-ASR

On-demand speech recognition with Qwen3-ASR-1.7B: each command starts a
pinned inference container, runs Transformers inference on the configured
accelerator, and removes the container afterward. VRAM is released when transcription
finishes; there is no persistent API server.

## Stack

| Component | Role |
|-----------|------|
| [Qwen3-ASR-1.7B](https://huggingface.co/Qwen/Qwen3-ASR-1.7B) | Speech recognition (Transformers, ~4.7 GB) |
| `qwenllm/qwen3-asr` pinned container (~14 GB) | CUDA inference environment |
| `rocm/pytorch` pinned container (~20 GB) | ROCm inference environment (local image built on top) |
| Qwen3-ForcedAligner-0.6B | Token timestamps |
| pyannote speaker-diarization-community-1 | Speaker assignment |
| FFmpeg | Audio extraction from video (mono 16 kHz) |
| Rootless Podman | Container runtime, NVIDIA or AMD GPU passthrough |

## Accelerators

The backend follows the host flags: `enableNvidia` selects `cuda`,
`enableRocm` selects `rocm`, and enabling Qwen3-ASR with neither set fails
evaluation. Options live under `_custom.services.ai.qwen3Asr`:

| Option | Default | Role |
|--------|---------|------|
| `accelerator` | from `enableNvidia`/`enableRocm` | `cuda` or `rocm`; selects image and devices |
| `dtype` | `bfloat16` | Torch dtype for all models |
| `chunkSeconds` | `240` | Default chunk length for `qwen3-asr-video` |
| `shmSize` | `4g` | `podman run --shm-size` |
| `tmpSize` | `4g` | tmpfs size mounted at `/tmp` in the container |
| `cuda.image` | pinned `qwenllm/qwen3-asr` | Upstream CUDA image |
| `rocm.baseImage` | pinned `rocm/pytorch` | Base of the local ROCm image |
| `rocm.gfxOverride` | `null` | `HSA_OVERRIDE_GFX_VERSION` inside the container |
| `rocm.devices` | `["/dev/kfd" "/dev/dri"]` | Device nodes handed to Podman |

On ROCm the first run pulls the ~20 GB `rocm/pytorch` base and builds a local
`qwen3-asr-rocm` image with `qwen-asr` and `pyannote.audio`; both commands
share it. ROCm's PyTorch exposes the GPU through the CUDA API, so the device
string stays `cuda:0`. The RX 6800 XT (gfx1030) has shipped kernels and needs
no override; cards without them, such as gfx1031 or gfx1032, need
`rocm.gfxOverride = "10.3.0"`.

## Setup

One-time prerequisites for the video pipeline:

1. Accept the model conditions at
   <https://huggingface.co/pyannote/speaker-diarization-community-1>.
2. Configure `personal-hugging-face-local-read-token` in
   `secrets-sops/personal.yaml`. An explicitly exported `HF_TOKEN` overrides
   the configured secret.

State: the pinned images live in rootless Podman's user container storage,
and model files persist in `~/.cache/qwen3-asr`. The first invocation also
builds a local inference image from the pinned base image and installs the
pinned pyannote runtime; later runs reuse both.

## Usage

Transcribe a local audio file:

```sh
qwen3-asr-transcribe recording.wav
qwen3-asr-transcribe --language English recording.mp3
qwen3-asr-transcribe --language Spanish part-*.wav
```

For a video, the helper extracts mono 16 kHz audio with FFmpeg, transcribes
it, adds token timestamps, and assigns speakers:

```sh
export HF_TOKEN=hf_...   # optional override
qwen3-asr-video video.mp4
qwen3-asr-video --language English --num-speakers 2 video.mkv
qwen3-asr-video --language es --min-speakers 2 --max-speakers 5 video.mkv
```

The command writes `video.txt` and `video.json` by default. The text file
has one timestamped speaker turn per line, while the versioned JSON file
retains ASR chunks, detected languages, aligned tokens, exclusive diarization
regions, and merged turns. Use `--output` and `--json-output` to choose other
paths.

Long audio is transcribed in chunks of `chunkSeconds` (240 s by default,
sized for an 8 GB GPU; gdesktop raises it to 480 for its 16 GB card).
Override the chunk duration per run if needed; smaller values use less VRAM
without changing the model or audio quality:

```sh
QWEN3_ASR_CHUNK_SECONDS=180 qwen3-asr-video long-video.mp4
```

The ASR, forced aligner, and diarization models are loaded sequentially
rather than simultaneously so the pipeline remains usable on an 8 GB
RTX 4060.

## Security model

The container receives only the temporary extracted audio read-only, the
inference script read-only, and the dedicated model cache. It does not
receive the containing video directory, the home directory, SSH/GPG keys, or
a Podman socket. No port is opened. After the image and all three models
have been downloaded once, disable container networking:

```sh
QWEN3_ASR_OFFLINE=1 qwen3-asr-video video.mp4
```
