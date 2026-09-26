# ASR

On-demand speech recognition with speaker diarization: `asr` starts a pinned
inference container, runs inference on the configured accelerator, and
removes the container afterward. VRAM is released when transcription
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
| FFmpeg | Audio extraction (mono 16 kHz) |
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
     the adapter's Python packages. `asr` builds `asr-<name>-cuda` on top of
     it with pyannote. Leave it `null` when the adapter does not support
     CUDA.
   - `pipPackages`: pip requirements installed into the local
     `asr-<name>-rocm` image.
   - `models`: the pinned Hugging Face models, each
     `{ repo; revision; role; }` with `role` either `transcriber` or
     `aligner`. The attribute name is how the Python adapter looks the model
     up. The core adds its own `diarizer`.
2. Create the Python adapter. It needs two functions; `models` maps each
   model name to `{"repo": ..., "revision": ...}`:
   - `load_transcriber(device, dtype, batch_size, models)` returns an object
     whose `transcribe(paths, language)` returns one result per path, each
     with `text` and `language`. `dtype` is a Torch dtype name; `language` is
     an ISO 639 code or `None` to detect it. The returned language may be a
     code or an English name.
   - `load_aligner(device, dtype, models)` returns an object whose
     `align(path, text, language)` returns units with `text`, `start`, and
     `end` in seconds relative to the chunk. An adapter whose transcriber
     returns timestamps itself would return `None`; the pipeline does not
     support that yet.
3. Set `asr.adapter = "<name>"`.

Inside the container the adapter name is `ASR_ADAPTER`, the mounted module
path is `ASR_ADAPTER_MODULE`, and the models, diarizer included, are the JSON
object `ASR_MODELS`. `tests/test_pipeline.py` runs the whole core against a
stub adapter; use it as a template:

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
| `chunkSeconds` | `240` | Default chunk length |
| `batchSize` | `1` | Chunks transcribed per generate call; raise until VRAM runs out |
| `shmSize` | `4g` | `podman run --shm-size` |
| `tmpSize` | `4g` | tmpfs size mounted at `/tmp` in the container |
| `qwen3.cuda.image` | pinned `qwenllm/qwen3-asr` | Upstream CUDA image of the `qwen3` adapter |
| `rocm.baseImage` | pinned `rocm/pytorch` | Base of the local ROCm image |
| `rocm.gfxOverride` | `null` | `HSA_OVERRIDE_GFX_VERSION` inside the container |
| `rocm.devices` | `["/dev/kfd" "/dev/dri"]` | Device nodes handed to Podman |

On ROCm the first run pulls the ~20 GB `rocm/pytorch` base and builds a local
`asr-<adapter>-rocm` image with the adapter's `pipPackages` and
`pyannote.audio`. On CUDA it builds `asr-<adapter>-cuda` from the adapter's
upstream image. ROCm's PyTorch exposes the GPU through the CUDA API, so the
device string stays `cuda:0`. The RX 6800 XT (gfx1030) has shipped kernels
and needs no override; cards without them, such as gfx1031 or gfx1032, need
`rocm.gfxOverride = "10.3.0"`.

## Setup

One-time prerequisites for speaker diarization:

1. Accept the model conditions at
   <https://huggingface.co/pyannote/speaker-diarization-community-1>.
2. Configure `personal-hugging-face-local-read-token` in
   `secrets-sops/personal.yaml`. An explicitly exported `HF_TOKEN` overrides
   the configured secret.

State: the pinned images live in rootless Podman's user container storage,
and model files persist in `~/.cache/asr/<adapter>`. The first invocation
also builds the local inference image; later runs reuse it.

## Usage

`asr` takes any audio or video file. It extracts the first audio stream as
mono 16 kHz with FFmpeg, transcribes it, adds word timestamps, and assigns
speakers:

```sh
export HF_TOKEN=hf_...   # optional override
asr video.mp4
asr --language English --num-speakers 2 video.mkv
asr --language es --min-speakers 2 --max-speakers 5 recording.mp3
```

`--no-diarize` skips word alignment and diarization. It only loads the ASR
model, needs no Hugging Face token, and writes one line per chunk:

```sh
asr --no-diarize recording.wav
```

The command writes `<stem>.txt` and `<stem>.json` next to the input by
default; `--output` and `--json-output` choose other paths. The text file has
one timestamped turn per line, prefixed with the speaker when diarized.

The JSON file (`schema_version` 2) holds:

| Key | Content |
|-----|---------|
| `adapter` | Adapter name |
| `models` | Every model used, with `repo`, `revision`, and `role` |
| `diarized` | `false` with `--no-diarize` |
| `source` | Input file name and duration |
| `requested_language`, `detected_languages` | ISO 639 codes |
| `chunks` | ASR chunks with their text and language |
| `tokens` | Aligned words with speakers; empty without diarization |
| `exclusive_diarization` | Speaker regions; empty without diarization |
| `turns` | Merged speaker turns, or one entry per chunk without diarization |

`--language` accepts an ISO 639 code or an English name and rejects
anything else before any work starts.

Long audio is transcribed in chunks of `chunkSeconds` (240 s by default,
sized for an 8 GB GPU; gdesktop raises it to 480 for its 16 GB card).
Override the chunk duration per run if needed; smaller values use less VRAM
without changing the model or audio quality:

```sh
ASR_CHUNK_SECONDS=180 asr long-video.mp4
```

The ASR, aligner, and diarization models are loaded sequentially rather than
simultaneously so the pipeline remains usable on an 8 GB RTX 4060.

## Security model

The container receives only the temporary extracted audio read-only, the
inference script and adapter read-only, and the dedicated model cache. It
does not receive the input file's directory, the home directory, SSH/GPG
keys, or a Podman socket. No port is opened. The hardening flags come from
`sandbox_args` in `../lib/container.sh`.

Each model that loads successfully leaves a marker under
`~/.cache/asr/<adapter>/asr-verified/`. Once every model a run needs has a
marker, `asr` runs with networking disabled. To force that before the
markers exist:

```sh
ASR_OFFLINE=1 asr video.mp4
```

## Migrating

From `qwen3-asr`: the module was `_custom.services.ai.qwen3Asr` with
`qwen3-asr-transcribe` and `qwen3-asr-video`. Rename the options to
`_custom.services.ai.asr`, replace the `QWEN3_ASR_` environment prefix with
`ASR_`, and keep the downloaded models:

```sh
mkdir -p ~/.cache/asr
mv ~/.cache/qwen3-asr ~/.cache/asr/qwen3
```

From `asr-transcribe` and `asr-video`: both are now `asr`. `asr-transcribe`
becomes `asr --no-diarize`, which takes one file and writes `.txt`/`.json`
instead of printing to stdout. The JSON moved to `schema_version` 2:
`backend` is now `adapter`, languages are ISO codes, and `models` and
`diarized` are new. The first run after upgrading goes online once to write
the offline markers.

Old `qwen3-asr-rocm`, `qwen3-asr-diarization`, and `asr-<adapter>-diarization`
images can be removed with `podman image rm`.
