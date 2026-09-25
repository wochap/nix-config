# PDF ingestion

`pdf-ingest` turns a local PDF into a portable document directory. It combines
native PDF data from PyMuPDF with the reading order and layout produced by a
layout adapter, PaddleOCR-VL-1.6 by default. It does not create embeddings,
contact a vector database, or run an indexing service.

Enable it with `_custom.services.ai.pdfIngest.enable`. It does not depend on
the screen `ocr` tool.

## Stack

| Component | Role |
|-----------|------|
| [PyMuPDF](https://pymupdf.readthedocs.io) | Native text, links, images, and tables, in a Bubblewrap sandbox |
| [PaddleOCR-VL](https://github.com/PaddlePaddle/PaddleOCR) | Default layout adapter (`adapters/paddleocr-vl`), in a Podman container |
| `../lib` | Shared container prelude and GPU options (`aiLib`) |

## Accelerators

The accelerator follows the host flags: `enableCuda` selects `cuda`,
`enableRocm` selects `rocm`, and enabling pdf-ingest with neither set fails
evaluation. Options live under `_custom.services.ai.pdfIngest`:

| Option | Default | Role |
|--------|---------|------|
| `adapter` | `paddleocr-vl` | Layout adapter under `adapters/` |
| `accelerator` | from `enableCuda`/`enableRocm` | `cuda` or `rocm`; selects the adapter's image and environment, and the devices |
| `dtype` | `float16` | Torch dtype for both models on ROCm (`float16`, `bfloat16`, `float32`) |
| `shmSize` | `2g` | `podman run --shm-size` |
| `tmpSize` | `4g` | tmpfs size mounted at `/tmp` in the container |
| `paddleocrVl.cuda.image` | pinned `paddleocr-vl` offline image | Upstream CUDA image, run directly |
| `paddleocrVl.rocm.baseImage` | pinned `rocm/pytorch` | Base of the local ROCm image |
| `rocm.gfxOverride` | `null` | `HSA_OVERRIDE_GFX_VERSION` inside the container |
| `rocm.devices` | `["/dev/kfd" "/dev/dri"]` | Device nodes handed to Podman |

| Accelerator | Image | Inference engine | Bundled cache |
|-------------|-------|------------------|---------------|
| `cuda` | upstream `paddleocr-vl:paddleocr3.6-nvidia-gpu-offline` | native Paddle, fp16 | `/home/paddleocr/.paddlex` |
| `rocm` | local `pdf-ingest-paddleocr-vl-rocm` built on `rocm/pytorch` | Transformers on ROCm PyTorch, `dtype` | `/root/.paddlex` |

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

## Setup

Fetch the inference image once:

```sh
pdf-ingest setup
```

On CUDA this pulls the immutable PaddleOCR 3.6 NVIDIA offline image. It is
pinned by SHA-256 and is large (allow roughly 20 GB of container storage,
plus temporary free space while it is pulled). It is PaddleOCR's CUDA 12.6
runtime for non-Blackwell NVIDIA GPUs. Rootless Podman, the NVIDIA container
toolkit/CDI, and a compatible NVIDIA driver must be working on the host.

On ROCm this pulls the ~30 GB `rocm/pytorch` base (shared with `asr`)
and builds the local `pdf-ingest-paddleocr-vl-rocm` image on top of it: it
installs the pinned PaddleOCR stack, downloads about 2.5 GB of weights from
Hugging Face, and verifies the pipeline offline on the CPU before the image is
tagged. The first build takes a while; a later `pdf-ingest` call rebuilds only
when the Containerfile or the base image changes.

Ingestion always uses `--pull=never` and `--network=none`; after setup, no
model or package download is possible. The process runs as container UID 0
inside Podman's rootless user namespace so output files map back to the
invoking host user; it still has all Linux capabilities dropped.

## Usage

```sh
pdf-ingest report.pdf                 # writes ./report/
pdf-ingest report.pdf ./documents/r1  # explicit destination
pdf-ingest --dpi 160 --min-dpi 120 report.pdf
pdf-ingest --batch-size 2 report.pdf
```

The defaults are 200 DPI, a 120 DPI retry floor, and one page per inference
batch. The layout adapter runs on every page, including digital PDFs, because
its layout and reading order form the structural frame. PyMuPDF text replaces
the layout text only when it is printable and sufficiently similar. Both
candidates and the selection reason remain in block provenance.

An interrupted run can be resumed by repeating exactly the same command.
Checkpoints live in `.pdf-ingest-state/` inside the destination and are tied to
the source SHA-256, extraction settings, and container digest. A completed
matching destination is a successful no-op. The command refuses a non-PDF,
an unrelated non-empty destination, or checkpoints made for other settings.
A destination or checkpoint made by an older schema is refused with a request
to re-ingest into a new directory.

On GPU out-of-memory errors (CUDA or HIP), the command clears the device
cache, reduces a batch larger than one, and then retries the page at
successively lower DPI down to `--min-dpi`. For an 8 GB RTX 4060, keep
`--batch-size 1`; use 160 DPI when a dense or very large page cannot complete
at 200 DPI. The 16 GB RX 6800 XT completes the defaults with headroom. Lower
DPI saves VRAM but can reduce small-text and formula accuracy.

## Output and schema

A successful destination contains only:

```text
document/
├── source.pdf
├── document.json
├── document.md
├── images/
└── raw/
    ├── pymupdf.json
    └── <layout adapter>.json    # paddleocr-vl.json by default
```

Budget approximately the source PDF size plus its extracted original images,
page-region PNG crops, and JSON. Image-heavy documents can require several
times the source size while checkpoints exist; the checkpoint directory is
removed after successful compaction.

`document.json` is canonical schema version 2. It uses stable page/block IDs,
displayed PDF coordinates in points with a top-left origin, ordered semantic
blocks, typed tables/cells/formulas/figures, links, section paths, parser
provenance, and explicit relationships. The layout adapter's raw pixel
coordinates and their render transform are retained in `raw/<adapter>.json`;
binary image data is stored once under `images/` and referenced relatively.
`document.md` is rendered only from the completed canonical JSON and contains
page comments and stable block anchors as HTML comments. Multi-line table
cells are joined with `<br>`, and text OCR'd from an embedded image region is
rendered as a fenced code block.

Schema version 2 names no specific adapter:

- `parsers` entries carry `"role": "native"` (PyMuPDF) or `"role": "layout"`
  (the layout adapter, with its `adapter`, `model`, `image`, and
  `accelerator`).
- `provenance.selection` holds `layout_text` and `native_text`; its `selected`
  field is `pymupdf` or the layout adapter's name, and its `reason` is one of
  `native_matches_ocr`, `layout_empty`, `candidate_mismatch`,
  `no_reliable_native_text`, `structural_block`, `unmatched_native`, or
  `original_embedded_asset`.
- `provenance.raw.layout` is a JSON pointer into `raw/<adapter>.json`, such as
  `/pages/0/result/parsing_res_list/3`; `provenance.raw.pymupdf` points into
  `raw/pymupdf.json`.

Version 1 used `paddle_text`, `paddle_empty`, and a per-adapter
`provenance.raw` key. Version 1 outputs are not converted; re-ingest them.

The final directory contains no absolute host paths, model cache, or partial
state, so it can be copied to another machine as-is.

## Isolation

The inference container can read only the selected PDF, the immutable pipeline
and adapter scripts, and files already inside its pinned image. Its only
persistent writable mount is the selected output directory. The host home
directory, SSH and GPG directories, agent sockets, Podman socket, and other
sibling files are not mounted. Networking and Podman's automatic
proxy-environment forwarding are disabled, PID/IPC/UTS/cgroup namespaces are
private, Linux capabilities are dropped, privilege escalation is disabled, and
the image filesystem is read-only. PaddleX's complete runtime cache is
redirected to bounded `/tmp`, while its bundled models and fonts are linked
back from their read-only image locations. The runtime cache and shared-memory
filesystems are discarded with the container; bundled models under
`/home/paddleocr/.paddlex` (CUDA) or `/root/.paddlex` (ROCm) remain read-only.
On ROCm the MIOpen kernel database and the Hugging Face cache are also
redirected to `/tmp`.

PyMuPDF extraction and page rendering run first with the Nix-provided PyMuPDF
package in a separate Bubblewrap sandbox. That phase has an empty environment,
no network namespace, and access only to the source PDF, output directory,
minimal virtual `/proc` and `/dev`, temporary memory, and the read-only Nix
store. It cannot see the host home directory or agent sockets either. The
inference image therefore does not need PyMuPDF installed and remains
unchanged.

NVIDIA CDI, or `/dev/kfd` and `/dev/dri` on ROCm, necessarily exposes the GPU
and its driver interface. As with any container, isolation still depends on
the host kernel, Podman, OCI runtime, and GPU driver being free of
container-escape vulnerabilities. Rootless execution limits a successful
escape to the invoking user's host permissions rather than granting host root
access.

## Optional GPU smoke test

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

## Adding an adapter

Each adapter is a directory under `adapters/` holding a NixOS module. The
module registers itself in the internal `adapterRegistry` option;
`default.nix` imports it. Add one import line there for a new directory.

1. Create `adapters/<name>/default.nix`. Declare adapter-specific options
   under `_custom.services.ai.pdfIngest.<camelName>` and set
   `_custom.services.ai.pdfIngest.adapterRegistry.<name>`:
   - `displayName`: name in log and build messages.
   - `module`: the Python adapter, mounted at `/opt/pdf-ingest/adapter.py`.
   - `image.<accelerator>`: `{ tag; context; buildArgs; }`. An empty
     `context` runs `tag` as pulled; otherwise `pdf-ingest` builds the
     Containerfile in `context` with `buildArgs` (one `KEY=VALUE` per line)
     on first use. `aiLib.mkContainerImage name file buildArgs` returns such
     a set with a content-hashed tag; name the image
     `pdf-ingest-<name>-<accelerator>`. A missing accelerator fails
     evaluation.
   - `containerEnv.<accelerator>`: `KEY=VALUE` strings passed to the
     container. Name the variables after the adapter, such as
     `PADDLEOCR_VL_ENGINE`.
2. Create the Python adapter. It does `import pdf_ingest as core` and exports
   `ADAPTER`, a `core.ParserAdapter` subclass with:
   - `name` (used in provenance and `raw/<name>.json`) and `model`.
   - `prepare_runtime()`: static; sets up caches before the first load.
   - `__init__(batch_size)`: loads the model.
   - `parse_page(image_path, dpi)`: returns `dpi`, `render_transform`, `raw`,
     and `blocks`. Each block has `type` (through `core.map_label`), `label`,
     `text`, `bbox` and `polygon` in PDF points (`core.pixel_box_to_points`),
     `parser_block_id`, `raw`, and `raw_path`, a JSON pointer into the page's
     `raw` result (`""` for the whole result).
   - `clear_cache()`: frees accelerator memory after an OOM.
   - `metadata()`: static; extra fields of the adapter's `parsers` entry in
     `document.json`.
3. Set `pdfIngest.adapter = "<name>"`.

The container image must contain Python, Pillow, and the adapter's own
packages; PyMuPDF runs outside it. `tests/test_pdf_ingest.py` loads the
PaddleOCR-VL adapter beside the core; use its fake adapter in
`test_inference_phase_does_not_require_pymupdf` as a template. Run the tests
with:

```sh
python3 -m unittest discover -s modules/nixos/services/ai/pdf-ingest/tests
```
