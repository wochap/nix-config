# Reranker

A Qwen3-Reranker GGUF served by llama.cpp (`llama-server --rerank --pooling
rank`) behind `/v1/rerank`. Shared by [GPT Researcher](../gpt-researcher/README.md)
and [wosarcher](../wosarcher/README.md).

```nix
_custom.services.ai.reranker = {
  enable = true;
  model = "Qwen/Qwen3-Reranker-4B";          # name clients send in the request
  modelUrl = "https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q8_0.gguf";
  # modelSha256 = "..."; # pin after the first download logs the hash
  # package = pkgs.llama-cpp-vulkan; # cached, avoids the CUDA compile
};
```

It adds two units: `reranker-model`, a oneshot that downloads the GGUF into
`/var/lib/reranker`, and the lazy `reranker`, listening on port 20820
(backend 20821). Clients use the public port, so the first request starts
the server. `accelerator` follows `enableCuda`/`enableRocm` and picks
`package`: `llama-cpp-rocm` on ROCm, `llama-cpp.override { cudaSupport =
true; }` on CUDA. `llama-cpp-rocm` comes from cache.nixos.org and carries
kernels for every gfx target ROCm was built for, gfx1030 included. The CUDA
build is not cached and compiles locally; set `package =
pkgs.llama-cpp-vulkan` for a cached NVIDIA build at some throughput cost.

## Sharing one GPU with Ollama

llama.cpp allocates weights plus KV cache and nothing more, so the reranker
and the Ollama embedding model stay resident together and need no phase
scheduling, no model eviction and no sleep mode. Budget the quantization
against the free VRAM: Q8_0 is about 5.1 GB resident, Q4_K_M about 2.5 GB.

Because llama.cpp never unloads on its own, `idleTimeout` (default 15
minutes, `null` to disable) adds `reranker-idle`, a timer that samples
`llamacpp:n_decode_total` on the server's `/metrics` every minute and stops
the unit once that counter has stood still for the whole window. The socket
proxy starts the server again on the next rerank, a few seconds later.
`llamacpp:prompt_tokens_total` stays at 0 for pooling requests, which is why
the decode counter is the activity signal. A rejected request never reaches
decode, so a `send_error` line in the unit's journal also counts as activity.
A batch in flight leaves a slot `is_processing`, and the watchdog never stops
the server then.

llama-server binds its port before the model has loaded and answers 503 until
then. An `ExecStartPost` holds the unit in `activating` until `/health`
returns 200, and the lazy proxy starts after the unit, so the first rerank
waits for the load instead of failing.

Pooling needs each query+document pair inside one physical batch, so the
server runs with `--batch-size` and `--ubatch-size` equal to `contextSize`.
With the default 512, every pair above 512 tokens fails with `input (N
tokens) is too large to process`.

## The GGUF

The file must come from a conversion through llama.cpp's reranker path: it
carries the `cls.output.weight` tensor and a `tokenizer.chat_template.rerank`
metadata key. A plain causal-LM Qwen3-Reranker conversion has no classifier
head and cannot rerank. `giladgd/Qwen3-Reranker-4B-GGUF` is verified working.
llama-server applies that template itself, so clients must not template the
pairs again.

## First start and verification

The first download takes a while. Watch it, then exercise the endpoint:

```sh
sudo systemctl start reranker
sudo journalctl -fu reranker-model
sudo journalctl -fu reranker
```

```sh
curl http://127.0.1.1:20821/health
curl -X POST http://127.0.1.1:20821/v1/rerank -H 'Content-Type: application/json' \
  -d '{"model":"Qwen/Qwen3-Reranker-4B","query":"capital of France","documents":["Paris is the capital of France.","Bananas are yellow."],"top_n":2}'
nvidia-smi                                # or rocm-smi --showmemuse
curl http://127.0.0.1:11434/api/ps        # both models resident at once
```

## Known limits

- `rocm.gfxOverride` cannot bridge a different ISA; it only helps a card that
  can pass as one `llama-cpp-rocm` already covers.
- The server holds its VRAM until the unit stops: `sudo systemctl stop
  reranker` before gaming or loading a large local LLM.
- Changing `modelUrl` downloads the new file on next use; the old GGUF stays
  in `/var/lib/reranker` until you delete it.
