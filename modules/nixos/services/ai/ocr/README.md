# OCR

`ocr` freezes the screen, lets you select a region with `slurp`, recognizes
the text inside it, and copies the result to the clipboard. Two backends are
available: RapidOCR (fast, local CPU/GPU inference) and GLM-OCR (vision LLM
through Ollama).

## Stack

| Component | Role |
|-----------|------|
| [RapidOCR](https://github.com/RapidAI/RapidOCR) | Default recognition engine (`rapidocr-text.py`) |
| Ollama + `glm-ocr:bf16` | GLM mode, served at `127.0.0.1:11434` |

## Setup

GLM mode additionally needs the `glm-ocr:bf16` model. The NixOS module
already adds it to `services.ollama.loadModels`, so after enabling, just
verify:

```sh
ollama list | grep glm-ocr
```

Or pull it manually:

```sh
ollama pull glm-ocr:bf16
```

## Usage

Run `ocr` and select a screen region. Recognized text is copied to the
clipboard:

```sh
ocr          # RapidOCR (default, fast/local)
ocr rapid    # RapidOCR explicitly
ocr glm      # GLM-OCR through local Ollama
```

Only one OCR selection can run at a time (flock-protected). Use RapidOCR for
everyday text capture; use GLM mode when the region needs vision-model
understanding (handwriting, tables, complex layouts).

## PDF ingestion

`pdf-ingest` turns a local PDF into a portable document directory. It combines
native PDF data from PyMuPDF with the reading order and layout produced by
PaddleOCR-VL-1.6. It does not create embeddings, contact a vector database, or
run an indexing service.

### Accelerators

The backend follows the host flags: `enableNvidia` selects `cuda`,
`enableRocm` selects `rocm`, and enabling OCR with neither set fails
evaluation. Options live under `_custom.services.ai.pdfIngest`:

| Option | Default | Role |
|--------|---------|------|
| `accelerator` | from `enableNvidia`/`enableRocm` | `cuda` or `rocm`; selects image, engine, and devices |
| `dtype` | `float16` | Torch dtype for both models on ROCm (`float16`, `bfloat16`, `float32`) |
| `shmSize` | `2g` | `podman run --shm-size` |
| `tmpSize` | `4g` | tmpfs size mounted at `/tmp` in the container |
| `cuda.image` | pinned `paddleocr-vl` offline image | Upstream CUDA image, run directly |
| `rocm.baseImage` | pinned `rocm/pytorch` | Base of the local ROCm image |
| `rocm.gfxOverride` | `null` | `HSA_OVERRIDE_GFX_VERSION` inside the container |
| `rocm.devices` | `["/dev/kfd" "/dev/dri"]` | Device nodes handed to Podman |

| Accelerator | Image | Inference engine | Bundled cache |
|-------------|-------|------------------|---------------|
| `cuda` | upstream `paddleocr-vl:paddleocr3.6-nvidia-gpu-offline` | native Paddle, fp16 | `/home/paddleocr/.paddlex` |
| `rocm` | local `pdf-ingest-rocm` built on `rocm/pytorch` | Transformers on ROCm PyTorch, `dtype` | `/root/.paddlex` |

Baidu's own AMD image targets MI300X and the Paddle HIP wheels ship no
gfx1030 kernels, so on ROCm the same PaddleOCR-VL-1.6 and PP-DocLayoutV3
checkpoints are loaded through PaddleX's Transformers engine instead. The
ROCm image pins `paddleocr[doc-parser]==3.7.0`, `paddlex==3.7.2`, and
`transformers==5.17.0` on top of the base image's torch and bakes the
safetensors weights in, so runtime still needs no network. ROCm's PyTorch
exposes the GPU through the CUDA API; the pipeline keeps `device="gpu:0"`.
The RX 6800 XT (gfx1030) has shipped kernels and needs no override; cards
without them, such as gfx1031 or gfx1032, need `rocm.gfxOverride = "10.3.0"`.
If a kernel rejects half precision on your card, set `dtype = "float32"`;
the 16 GB RX 6800 XT has room for it.

### Setup

Fetch the inference image once:

```sh
pdf-ingest setup
```

On CUDA this pulls the immutable PaddleOCR 3.6 NVIDIA offline image. It is
pinned by SHA-256 and is large (allow roughly 20 GB of container storage,
plus temporary free space while it is pulled). It is PaddleOCR's CUDA 12.6
runtime for non-Blackwell NVIDIA GPUs. Rootless Podman, the NVIDIA container
toolkit/CDI, and a compatible NVIDIA driver must be working on the host.

On ROCm this pulls the ~30 GB `rocm/pytorch` base (shared with `qwen3-asr`)
and builds the local `pdf-ingest-rocm` image on top of it: it installs the
pinned PaddleOCR stack, downloads about 2.5 GB of weights from Hugging Face,
and verifies the pipeline offline on the CPU before the image is tagged. The
first build takes a while; a later `pdf-ingest` call rebuilds only when the
Containerfile or the base image changes.

Ingestion always uses `--pull=never` and `--network=none`; after setup, no
model or package download is possible. The process runs as container UID 0
inside Podman's rootless user namespace so output files map back to the
invoking host user; it still has all Linux capabilities dropped.

### Usage

```sh
pdf-ingest report.pdf                 # writes ./report/
pdf-ingest report.pdf ./documents/r1  # explicit destination
pdf-ingest --dpi 160 --min-dpi 120 report.pdf
pdf-ingest --batch-size 2 report.pdf
```

The defaults are 200 DPI, a 120 DPI retry floor, and one page per inference
batch. PaddleOCR runs on every page, including digital PDFs, because its layout
and reading order form the structural frame. PyMuPDF text replaces OCR text
only when it is printable and sufficiently similar. Both candidates and the
selection reason remain in block provenance.

An interrupted run can be resumed by repeating exactly the same command.
Checkpoints live in `.pdf-ingest-state/` inside the destination and are tied to
the source SHA-256, extraction settings, and container digest. A completed
matching destination is a successful no-op. The command refuses a non-PDF,
an unrelated non-empty destination, or checkpoints made for other settings.

On GPU out-of-memory errors (CUDA or HIP), the command clears the device
cache, reduces a batch larger than one, and then retries the page at
successively lower DPI down to `--min-dpi`. For an 8 GB RTX 4060, keep
`--batch-size 1`; use 160 DPI when a dense or very large page cannot complete
at 200 DPI. The 16 GB RX 6800 XT completes the defaults with headroom. Lower
DPI saves VRAM but can reduce small-text and formula accuracy.

### Output and schema

A successful destination contains only:

```text
document/
├── source.pdf
├── document.json
├── document.md
├── images/
└── raw/
    ├── pymupdf.json
    └── paddleocr-vl.json
```

Budget approximately the source PDF size plus its extracted original images,
page-region PNG crops, and JSON. Image-heavy documents can require several
times the source size while checkpoints exist; the checkpoint directory is
removed after successful compaction.

`document.json` is canonical schema version 1. It uses stable page/block IDs,
displayed PDF coordinates in points with a top-left origin, ordered semantic
blocks, typed tables/cells/formulas/figures, links, section paths, parser
provenance, and explicit relationships. Raw Paddle pixel coordinates and their
render transform are retained in `raw/paddleocr-vl.json`; binary image data is
stored once under `images/` and referenced relatively. `document.md` is rendered
only from the completed canonical JSON and contains page comments and stable
block anchors as HTML comments. Multi-line table cells are joined with `<br>`,
and text OCR'd from an embedded image region is rendered as a fenced code block.

The final directory contains no absolute host paths, model cache, or partial
state, so it can be copied to another machine as-is.

### Isolation

The inference container can read only the selected PDF, the immutable pipeline
script, and files already inside its pinned image. Its only persistent writable
mount is the selected output directory. The host home directory, SSH and GPG
directories, agent sockets, Podman socket, and other sibling files are not
mounted. Networking and Podman's automatic proxy-environment forwarding are
disabled, PID/IPC/UTS/cgroup namespaces are private, Linux capabilities are
dropped, privilege escalation is disabled, and the image filesystem is
read-only. PaddleX's complete runtime cache is redirected to bounded `/tmp`,
while its bundled models and fonts are linked back from their read-only image
locations. The runtime cache and shared-memory filesystems are discarded with
the container; bundled models under `/home/paddleocr/.paddlex` (CUDA) or
`/root/.paddlex` (ROCm) remain read-only. On ROCm the MIOpen kernel database
and the Hugging Face cache are also redirected to `/tmp`.

PyMuPDF extraction and page rendering run first with the Nix-provided PyMuPDF
package in a separate Bubblewrap sandbox. That phase has an empty environment,
no network namespace, and access only to the source PDF, output directory,
minimal virtual `/proc` and `/dev`, temporary memory, and the read-only Nix
store. It cannot see the host home directory or agent sockets either. The
PaddleOCR image therefore does not need PyMuPDF installed and remains unchanged.

NVIDIA CDI, or `/dev/kfd` and `/dev/dri` on ROCm, necessarily exposes the GPU
and its driver interface. As with any container, isolation still depends on the host kernel, Podman, OCI runtime, and
GPU driver being free of container-escape vulnerabilities. Rootless execution
limits a successful escape to the invoking user's host permissions rather than
granting host root access.

### Optional GPU smoke test

After setup, ingest a short local PDF and check the result without downloading
anything:

```sh
pdf-ingest --dpi 160 sample.pdf /tmp/sample-document
find /tmp/sample-document -maxdepth 2 -type f -printf '%P\n' | sort
python -m json.tool /tmp/sample-document/document.json >/dev/null
test "$(find /tmp/sample-document -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | tr '\n' ' ')" = \
  'document.json document.md images raw source.pdf '
```

Run the same command again to confirm the completed no-op. The launcher has
networking disabled unconditionally; `podman inspect` of a running container,
when testing with a sufficiently long document, should report network mode
`none`. Re-ingesting the same file and settings in a new empty destination
should produce the same block IDs.
