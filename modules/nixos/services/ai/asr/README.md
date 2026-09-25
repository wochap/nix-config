# ASR

On-demand speech recognition with speaker diarization: each command starts a
pinned inference container, runs inference on the configured accelerator,
and removes the container afterward. VRAM is released when transcription
finishes; there is no persistent API server.

The speech model is a pluggable adapter. The core (chunking, diarization,
speaker assignment, turns, rendering, validation, container and security
wrapper) is shared; an adapter under `adapters/` supplies the ASR model and
the word aligner. The container prelude and GPU options come from `../lib`
(`aiLib`), shared with `pdf-ingest`.

## Stack

| Component | Role |
|-----------|------|
| Adapter (default `qwen3`) | Speech recognition and word timestamps |
| `rocm/pytorch` pinned container (~20 GB) | ROCm inference environment (local image built on top) |
| pyannote speaker-diarization-community-1 | Speaker assignment |
| FFmpeg | Audio extraction from video (mono 16 kHz) |
| Rootless Podman | Container runtime, NVIDIA or AMD GPU passthrough |

## Adapters

Select one with `_custom.services.ai.asr.adapter`.

| Adapter | Models | CUDA image |
|---------|--------|------------|
| `qwen3` | [Qwen3-ASR-1.7B](https://huggingface.co/Qwen/Qwen3-ASR-1.7B) (~4.7 GB) and Qwen3-ForcedAligner-0.6B | pinned `qwenllm/qwen3-asr` (~14 GB), option `qwen3.cuda.image` |

### Adding an adapter

Each adapter is a directory under `adapters/` holding a NixOS module. The
module registers itself in the internal `adapterRegistry` option;
`default.nix` imports it. Add one import line there for a new directory.

1. Create `adapters/<name>/default.nix`. Declare adapter-specific options
   under `_custom.services.ai.asr.<camelName>` and set
   `_custom.services.ai.asr.adapterRegistry.<name>`:
   - `module`: the Python adapter, mounted at `/opt/asr/adapter.py`.
   - `image.cuda`: `{ tag; }` of an upstream CUDA image that already contains
     the adapter's Python packages. `asr-transcribe` runs it directly and
     `asr-video` builds `asr-<name>-diarization` on top of it. Leave it
     `null` when the adapter does not support CUDA.
   - `pipPackages`: pip requirements installed into the local
     `asr-<name>-rocm` image.
   - `revisions`: attrset of model pins, exported as `ASR_REVISION_<KEY>`.
   - `cachedFiles.transcriber` and `cachedFiles.aligner`: Hugging Face
     snapshot files relative to the model cache. When all exist, the
     commands run without network access.
2. Create the Python adapter. It needs two functions:
   - `load_transcriber(device, dtype, batch_size)` returns an object whose
     `transcribe(paths, language)` returns one result per path, each with
     `text` and `language`. `dtype` is a Torch dtype name; `language` is an
     English language name or `None` to detect it.
   - `load_aligner(device, dtype)` returns an object whose
     `align(path, text, language)` returns units with `text`, `start`, and
     `end` in seconds relative to the chunk. An adapter whose transcriber
     returns timestamps itself would return `None`; the pipeline does not
     support that yet.
3. Set `asr.adapter = "<name>"`.

Inside the container the adapter name is `ASR_ADAPTER` and the mounted module
path is `ASR_ADAPTER_MODULE`. `tests/test_pipeline.py` runs the whole core
against a stub adapter; use it as a template:

```sh
python3 -m unittest discover -s modules/nixos/services/ai/asr/tests
```

## Accelerators

The accelerator follows the host flags: `enableCuda` selects `cuda`,
`enableRocm` selects `rocm`, and enabling ASR with neither set fails
evaluation. Options live under `_custom.services.ai.asr`:

| Option | Default | Role |
|--------|---------|------|
| `adapter` | `qwen3` | Adapter under `adapters/` |
| `accelerator` | from `enableCuda`/`enableRocm` | `cuda` or `rocm`; selects image and devices |
| `dtype` | `bfloat16` | Torch dtype for all models |
| `chunkSeconds` | `240` | Default chunk length for `asr-video` |
| `batchSize` | `1` | Chunks transcribed per generate call in `asr-video`; raise until VRAM runs out |
| `shmSize` | `4g` | `podman run --shm-size` |
| `tmpSize` | `4g` | tmpfs size mounted at `/tmp` in the container |
| `qwen3.cuda.image` | pinned `qwenllm/qwen3-asr` | Upstream CUDA image of the `qwen3` adapter |
| `rocm.baseImage` | pinned `rocm/pytorch` | Base of the local ROCm image |
| `rocm.gfxOverride` | `null` | `HSA_OVERRIDE_GFX_VERSION` inside the container |
| `rocm.devices` | `["/dev/kfd" "/dev/dri"]` | Device nodes handed to Podman |

On ROCm the first run pulls the ~20 GB `rocm/pytorch` base and builds a local
`asr-<adapter>-rocm` image with the adapter's `pipPackages` and
`pyannote.audio`; both commands share it. ROCm's PyTorch exposes the GPU through the CUDA API, so the device
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
and model files persist in `~/.cache/asr/<adapter>`. The first invocation also
builds a local inference image from the pinned base image and installs the
pinned pyannote runtime; later runs reuse both.

## Usage

Transcribe a local audio file:

```sh
asr-transcribe recording.wav
asr-transcribe --language English recording.mp3
asr-transcribe --language Spanish part-*.wav
```

For a video, the helper extracts mono 16 kHz audio with FFmpeg, transcribes
it, adds token timestamps, and assigns speakers:

```sh
export HF_TOKEN=hf_...   # optional override
asr-video video.mp4
asr-video --language English --num-speakers 2 video.mkv
asr-video --language es --min-speakers 2 --max-speakers 5 video.mkv
```

The command writes `video.txt` and `video.json` by default. The text file
has one timestamped speaker turn per line, while the versioned JSON file
retains ASR chunks, detected languages, aligned tokens, exclusive diarization
regions, merged turns, and the adapter name (under the `backend` key). Use `--output` and
`--json-output` to choose other paths.

Long audio is transcribed in chunks of `chunkSeconds` (240 s by default,
sized for an 8 GB GPU; gdesktop raises it to 480 for its 16 GB card).
Override the chunk duration per run if needed; smaller values use less VRAM
without changing the model or audio quality:

```sh
ASR_CHUNK_SECONDS=180 asr-video long-video.mp4
```

The ASR, aligner, and diarization models are loaded sequentially
rather than simultaneously so the pipeline remains usable on an 8 GB
RTX 4060.

## Security model

The container receives only the temporary extracted audio read-only, the
inference script and adapter read-only, and the dedicated model
cache. It does not
receive the containing video directory, the home directory, SSH/GPG keys, or
a Podman socket. No port is opened. After the image and all three models
have been downloaded once, disable container networking:

```sh
ASR_OFFLINE=1 asr-video video.mp4
```

## Migrating from qwen3-asr

The module was `_custom.services.ai.qwen3Asr` with `qwen3-asr-transcribe`
and `qwen3-asr-video`. Rename the options to `_custom.services.ai.asr`, use
`asr-transcribe` and `asr-video`, replace the `QWEN3_ASR_` environment
prefix with `ASR_`, and keep the downloaded models:

```sh
mkdir -p ~/.cache/asr
mv ~/.cache/qwen3-asr ~/.cache/asr/qwen3
```

Old `qwen3-asr-rocm` and `qwen3-asr-diarization` images can be removed with
`podman image rm`.
