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

### Setup

Pull the immutable PaddleOCR 3.6 NVIDIA offline image once:

```sh
pdf-ingest setup
```

The image is pinned by SHA-256 and is large (allow roughly 20 GB of container
storage, plus temporary free space while it is pulled). It is PaddleOCR's
CUDA 12.6 runtime for non-Blackwell NVIDIA GPUs. Ingestion always uses
`--pull=never` and `--network=none`; after setup, no model or package download
is possible. Rootless Podman, the NVIDIA container toolkit/CDI, and a compatible
NVIDIA driver must be working on the host.

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

On CUDA out-of-memory errors, the command clears the device cache, reduces a
batch larger than one, and then retries the page at successively lower DPI down
to `--min-dpi`. For an 8 GB RTX 4060, keep `--batch-size 1`; use 160 DPI when a
dense or very large page cannot complete at 200 DPI. Lower DPI saves VRAM but
can reduce small-text and formula accuracy.

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
block anchors.

The final directory contains no absolute host paths, model cache, or partial
state, so it can be copied to another machine as-is.

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
