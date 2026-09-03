# OCR

It requires a Wayland session with `wayfreeze`, `slurp`, `grim`, `wl-copy`, and
`notify-send`, plus `~/.config/scripts/theme-colors.sh`. GLM mode also requires
Ollama and the `glm-ocr:bf16` model:

```sh
ollama pull glm-ocr:bf16
```

The NixOS module already adds this model to `services.ollama.loadModels`.

Run `ocr` and select a screen region. Recognized text is copied to the
clipboard:

```sh
ocr          # RapidOCR (default, fast/local)
ocr rapid    # RapidOCR explicitly
ocr glm      # GLM-OCR through local Ollama
```
