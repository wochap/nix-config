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
