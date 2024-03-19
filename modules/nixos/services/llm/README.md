## LLM

### Downloading model

* https://ollama.com/library
* https://huggingface.co/models

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

### Usage of `Modelfile`s

You can download `Modelfile`s at https://openwebui.com/

```sh
$ ollama create <name> -f <location of the file>'

# e.g.
$ ollama create "deepseek-coder:33b-instruct-q4_K_M_glegion" -f ./models/glegion/Modelfile_deepseek-coder:33b-instruct-q4_K_M
```
