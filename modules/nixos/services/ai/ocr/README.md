# OCR

`ocr` freezes the screen, lets you select a region with `slurp`, recognizes
the text inside it, and copies the result to the clipboard. Two adapters are
available: RapidOCR (fast, local CPU inference) and GLM-OCR (vision LLM
through Ollama). PDF ingestion lives in [`../pdf-ingest`](../pdf-ingest/README.md).

## Stack

| Component | Role |
|-----------|------|
| [RapidOCR](https://github.com/RapidAI/RapidOCR) | Default adapter (`adapters/rapid`) |
| Ollama + `glm-ocr:bf16` | GLM adapter (`adapters/glm`), served at `127.0.0.1:11434` |

## Setup

The GLM adapter needs the `glm-ocr:bf16` model. The NixOS module
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
ocr          # default adapter (RapidOCR, fast/local)
ocr rapid    # RapidOCR explicitly
ocr glm      # GLM-OCR through local Ollama
```

Options live under `_custom.services.ai.ocr`:

| Option | Default | Role |
|--------|---------|------|
| `adapters` | `["rapid" "glm"]` | Adapters `ocr` offers; only these build and load their Ollama models |
| `defaultAdapter` | `rapid` | Adapter used without an argument; must be in `adapters` |

A host that never uses GLM can set `adapters = [ "rapid" ]`, which also keeps
`glm-ocr:bf16` out of `services.ollama.loadModels`.

Only one OCR selection can run at a time (flock-protected). Use RapidOCR for
everyday text capture; use GLM when the region needs vision-model
understanding (handwriting, tables, complex layouts).

## Adding an adapter

Each adapter is a directory under `adapters/` holding a NixOS module. The
module registers itself in the internal `adapterRegistry` option;
`default.nix` imports it. Add one import line there for a new directory.

1. Create `adapters/<name>/default.nix` and set
   `_custom.services.ai.ocr.adapterRegistry.<name>`:
   - `label`: name shown in notifications, as in "`<label>` Completed".
   - `command`: store path of an executable. `ocr` calls it as
     `command IMAGE`. It prints the recognized text on stdout and exits
     nonzero on failure. The last stderr line becomes the failure
     notification, so make it a short sentence.
   - `ollamaModels` (optional): models added to `services.ollama.loadModels`.
2. Keep temporary files inside the adapter (`mktemp` plus a trap). `ocr`
   only owns the captured image and the output.
3. Add the name to `ocr.adapters` on the hosts that want it.

`ocr <name>` then runs the adapter; an unknown name prints the enabled
names.
