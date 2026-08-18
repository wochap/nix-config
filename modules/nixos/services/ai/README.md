## LLM

### Downloading model

- https://ollama.com/library
- https://huggingface.co/models

### Selecting models

Looking the following model name: `deepseek-coder:33b-instruct-q4_K_M`

- `33b` refers to the parameters, increasing the number generates better responses, but it also increases VRAM/RAM usage
- `q4` represents quantization bits, reducing the number decreases VRAM/RAM usage, but it also reduces the precision of responses
- `_K` suggests these versions might be quantized versions of the base models
- `_M` represent different sizes of the quantized models

### Downloading models

```sh
$ ollama pull <model>

# e.g.
$ ollama pull deepseek-coder:33b-instruct-q4_K_M
```

To download from huggingface:

```sh
$ huggingface-cli download <user/model> <file name>

# e.g.
$ huggingface-cli download TheBloke/WhiteRabbitNeo-13B-GGUF whiterabbitneo-13b.Q5_K_M.gguf
```

then create a Modelfile, `FROM` should point to path of the

### Usage of `Modelfile`s

You can download `Modelfile`s at https://openwebui.com/

```sh
$ ollama create <name> -f <location of the file>'

# e.g.
$ ollama create "deepseek-coder:33b-instruct-q4_K_M_glegion" -f ./models/glegion/Modelfile_deepseek-coder:33b-instruct-q4_K_M
```

### Testing models

```sh
$ curl http://localhost:11434/api/generate -d '{
  "model": "deepseek-coder:33b-instruct-q4_K_M",
  "prompt": "Why is the sky blue?",
  "options": {
    "num_gpu": 1,
    "num_thread": 8
  }
}
```

- `num_gpu` you need to test starting from 1 and increase until it uses almost all your available VRAM
- `num_thread` represents the number of physical cores

To calculate how fast the response is generated in tokens per second (token/s), divide eval_count / (eval_duration / 1000000000)

## OmniRoute chat helper

`omniroute-chat` sends an OpenAI-compatible chat request to the local OmniRoute instance. It is installed system-wide when `_custom.services.ai.enableOmniRoute` is enabled and is used by `voice-clean` and `newsboat-summary`.

Configure OmniRoute before using the helper:

1. In **Dashboard → Endpoints**, create an endpoint API key and store its value in the SOPS secret `local-omniroute-secret-key`.
2. In **Dashboard → Combos**, create a persisted combo named `desktop-free`.
3. Select the **Priority** strategy for strict cloud-first ordering. **Fill First** can be used instead when each provider's available quota should be consumed before advancing.
4. Add the preferred free cloud provider models first, in desired order.
5. Add `glegion-qwen3.5:4b` through the Ollama provider as the final target.
6. In **Dashboard → Settings → Resilience**, enable connection cooldown, upstream retry hints, rate-limit auto-detection, and the provider circuit breaker. These allow quota, rate-limit, connection, and provider failures to advance through the combo.

By default, the helper uses:

- Base URL: `https://omniroute.wochap.local/v1`
- Model/combo: `desktop-free`
- API key file: `/run/secrets/local-omniroute-secret-key`

Override the combo used by an existing consumer:

```sh
$ OMNIROUTE_MODEL=another-combo voice-clean
```

Override the endpoint and API key, or invoke the helper directly:

```sh
$ OMNIROUTE_BASE_URL=http://127.0.1.1:20128/v1 \
    OMNIROUTE_API_KEY=... \
    omniroute-chat --model desktop-free < request.json
```

## Whisper cpp

Downloading models for whisper-cpp

```sh
$ git clone https://github.com/ggerganov/whisper.cpp.git
$ cd whisper.cpp
$ sh ./models/download-ggml-model.sh large-v3
```

Running

```sh
$ whisper-cli -m /path-to/whisper.cpp/models/ggml-large-v3.bin -f audio.wav
```

[Available models](https://github.com/ggerganov/whisper.cpp/blob/master/models/README.md#available-models)
