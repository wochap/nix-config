# Models

Notes and Modelfiles for managing LLM models used by the AI services, plus
whisper.cpp speech recognition.

## Model naming

Looking at a model name such as `deepseek-coder:33b-instruct-q4_K_M`:

- `33b` refers to the parameters; increasing the number generates better
  responses but also increases VRAM/RAM usage
- `q4` represents quantization bits; reducing the number decreases VRAM/RAM
  usage but reduces the precision of responses
- `_K` suggests these versions are quantized versions of the base models
- `_M` represents different sizes of the quantized models

## Downloading models

From the Ollama library:

```sh
ollama pull deepseek-coder:33b-instruct-q4_K_M
```

From Hugging Face:

```sh
huggingface-cli download TheBloke/WhiteRabbitNeo-13B-GGUF \
    whiterabbitneo-13b.Q5_K_M.gguf
```

then create a Modelfile whose `FROM` points to the downloaded file.

Sources: <https://ollama.com/library> and <https://huggingface.co/models>.

## Custom glegion models

This directory contains the Modelfiles for the models the services expect.
Create them with `ollama create` (run from this directory):

```sh
ollama create "glegion-qwen3.5:4b" -f ./glegion-qwen3.5:4b
ollama create "glegion-desktop-assistant-qwen3.5:4b" -f ./glegion-desktop-assistant-qwen3.5:4b
ollama create "glegion-qwen3-embedding:4b" -f ./glegion-qwen3-embedding:4b
```

- `glegion-qwen3.5:4b` — final fallback target in the OmniRoute
  `desktop-free` combo
- `glegion-qwen3-embedding:4b` — embeddings for Firecrawl

You can also download community Modelfiles from <https://openwebui.com/>:

```sh
ollama create "deepseek-coder:33b-instruct-q4_K_M_glegion" \
    -f ./models/glegion/Modelfile_deepseek-coder:33b-instruct-q4_K_M
```

## Testing models

```sh
curl http://localhost:11434/api/generate -d '{
  "model": "deepseek-coder:33b-instruct-q4_K_M",
  "prompt": "Why is the sky blue?",
  "options": {
    "num_gpu": 1,
    "num_thread": 8
  }
}'
```

- `num_gpu` — test starting from 1 and increase until it uses almost all your
  available VRAM
- `num_thread` — the number of physical cores

To calculate generation speed in tokens per second (token/s), divide
`eval_count / (eval_duration / 1000000000)`.

## whisper.cpp

Download a ggml model:

```sh
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
sh ./models/download-ggml-model.sh large-v3
```

Run it:

```sh
whisper-cli -m /path-to/whisper.cpp/models/ggml-large-v3.bin -f audio.wav
```

The AI bundle also ships the `wis` alias (transcribe to VTT) and the `ytaw`
alias (download a video as 16 kHz WAV); see
[../scripts/README.md](../scripts/README.md).

[Available models](https://github.com/ggerganov/whisper.cpp/blob/master/models/README.md#available-models)
