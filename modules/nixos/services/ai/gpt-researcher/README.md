# GPT Researcher

Self-hosted [GPT Researcher](https://github.com/assafelovic/gpt-researcher):
an autonomous research agent with a Next.js UI at
<https://gpt-researcher.wochap.local> and a FastAPI backend at
<https://gpt-researcher-api.wochap.local>.

## Stack

| Component | Role |
|-----------|------|
| `gpt-researcher` local OCI image | FastAPI research backend |
| `gptr-nextjs` local OCI image | Next.js web UI |
| SearxNG | Search retriever |
| [Firecrawl](../firecrawl/README.md) | Page scraping |
| Ollama | Embeddings for context retrieval |
| llama.cpp (`llama-server`, built for this host's GPU) | Optional Qwen3 reranker |
| SOPS | Provider keys without touching the Nix store |

## Setup

```nix
_custom.services.ai = {
  enable = true;
  gptResearcher = {
    enable = true;
    environmentFile = config.sops.templates."gpt-researcher.env".path;
  };
};
```

Keep provider keys out of the Nix store by rendering the environment file
with SOPS. A basic OpenAI and Tavily configuration contains:

```dotenv
OPENAI_API_KEY=...
TAVILY_API_KEY=...
```

The environment file accepts GPT Researcher's other provider, model,
retriever, and scraper settings as well.

Also required:

- Define the `research-fast` and `research-smart` model combos in
  [OmniRoute](../omniroute/README.md). Combos are dashboard state stored in
  OmniRoute's SQLite database, so recreate them on every host.
- Create the Ollama embedding model named by
  `_custom.services.ai.ollamaEmbeddingModel` (default
  `glegion-qwen3-embedding:4b`) from [ollama/models](../ollama/models/README.md).

## Models and token limits

GPT Researcher's token budgets (`FAST_TOKEN_LIMIT`, `SMART_TOKEN_LIMIT`,
`STRATEGIC_TOKEN_LIMIT`, `TOTAL_WORDS`, `SUMMARY_TOKEN_LIMIT`,
`BROWSE_CHUNK_MAX_LENGTH`, `MAX_ITERATIONS`, `MAX_SUBTOPICS`) derive from the
models behind the OmniRoute combos, so retargeting a combo only needs a preset
change here:

```nix
_custom.services.ai = {
  gptResearcher.smartModel = "deepseek-v4-flash"; # research-smart combo
  gptResearcher.fastModel = "deepseek-v4-flash"; # research-fast combo
  # gptResearcher.strategicModel defaults to the smart model
  ollamaEmbeddingModel = "gdesktop-qwen3-embedding:4b";
  gptResearcher.embeddingContextTokens = 49152; # num_ctx of that Modelfile
};
```

Each model option takes a preset name or an explicit
`{ contextTokens; maxOutputTokens; }` attribute set. Presets are defined in
`default.nix` with their sources:

| Preset | Context | Max output | Backing model |
|--------|---------|------------|---------------|
| `deepseek-v4-flash` | 1048576 | 384000 | DeepSeek V4 Flash (DeepSeek API) |
| `gemma4-31b` | 262144 | 32768 | Gemma 4 31B (OpenRouter / Ollama cloud) |
| `qwen3-8-max` | 1000000 | 131072 | Qwen3.8-Max (Alibaba Model Studio) |
| `qwen3-5-9b-local` | 32768 | 8192 | `gdesktop-qwen3.5:9b` on local Ollama |
| `glegion-cloud-smart` | 262144 | 131072 | glegion's hand-tuned smart limits |
| `glegion-cloud-fast` | 262144 | 12000 | glegion's hand-tuned fast limits |
| `glegion-cloud-strategic` | 262144 | 16000 | glegion's hand-tuned strategic limits |

Derivation: each `*_TOKEN_LIMIT` is `min maxOutputTokens (contextTokens / 2)`,
capped at 131072 (GPT Researcher rejects `max_tokens` above 200000);
`TOTAL_WORDS = min 20000 (SMART_TOKEN_LIMIT / 6)`;
`SUMMARY_TOKEN_LIMIT = max 500 (FAST_TOKEN_LIMIT / 6)`;
`BROWSE_CHUNK_MAX_LENGTH` is capped at 24000 characters, twice the fast
model's remaining prompt budget, and three times the embedding context;
`MAX_ITERATIONS`/`MAX_SUBTOPICS` are 4 above a 100k smart context, 3 above
32k, and 2 otherwise.

`_custom.services.ai.gptResearcher.settings` accepts raw environment
overrides (`attrsOf str`) merged after the derived values, for example
`{ MAX_SUBTOPICS = "6"; }`.

Both containers start lazily on the first request. Reports, logs, and
uploaded documents persist below `/var/lib/gpt-researcher`.

## Reranker

`gptResearcher.reranker.enable` switches retrieval to the fork's `local_gpu`
pipeline, per sub-query:

```
scrape -> split (chunkSize chars)
       -> Ollama embeddings -> cosine top embeddingTopK
       -> llama-server /v1/rerank (Qwen3-Reranker) -> top rerankTopK -> LLM
```

It adds two units: `gpt-researcher-reranker-model`, a oneshot that downloads
the GGUF into `/var/lib/gpt-researcher/reranker` at boot, and the lazy
`gpt-researcher-reranker`, running `llama-server --rerank --pooling rank` on
port 20820 (backend 20821). `reranker.accelerator` follows
`enableCuda`/`enableRocm` and picks `reranker.package`: `llama-cpp-rocm` on
ROCm, `llama-cpp.override { cudaSupport = true; }` on CUDA. `llama-cpp-rocm`
comes from cache.nixos.org and carries kernels for every gfx target ROCm was
built for, gfx1030 included. The CUDA build is not cached and compiles
locally; set `package = pkgs.llama-cpp-vulkan` for a cached NVIDIA build at
some throughput cost.

```nix
_custom.services.ai.gptResearcher.reranker = {
  enable = true;
  model = "Qwen/Qwen3-Reranker-4B";          # name sent in the request
  modelUrl = "https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q8_0.gguf";
  # modelSha256 = "..."; # pin after the first download logs the hash
  # package = pkgs.llama-cpp-vulkan; # cached, avoids the CUDA compile
};
```

### Sharing one GPU with Ollama

llama.cpp allocates weights plus KV cache and nothing more, so the reranker
and the Ollama embedding model stay resident together and the rerank stage
needs no phase scheduling, no model eviction and no sleep mode. Budget the
quantization against the free VRAM: Q8_0 is about 5.1 GB resident, Q4_K_M
about 2.5 GB.

Because llama.cpp never unloads on its own, `reranker.idleTimeout` (default 15
minutes, `null` to disable) adds `gpt-researcher-reranker-idle`, a timer that
samples `llamacpp:n_decode_total` on the server's `/metrics` every minute and
stops the unit once that counter has stood still for the whole window. The
socket proxy starts the server again on the next rerank, a few seconds later.
`llamacpp:prompt_tokens_total` stays at 0 for pooling requests, which is why
the decode counter is the activity signal. A rejected request never reaches
decode, so a `send_error` line in the unit's journal also counts as activity.
A batch in flight leaves a slot `is_processing`, and the watchdog never stops
the server then.

llama-server binds its port before the model has loaded and answers 503 until
then. An `ExecStartPost` holds the unit in `activating` until `/health`
returns 200, and the lazy proxy starts after the unit, so the first rerank of
a run waits for the load instead of failing.

`chunkSize` must fit `contextSize` together with the rerank template and the
query (about 4 characters per token). Pooling also needs each pair inside one
physical batch, so the server runs with `--batch-size` and `--ubatch-size`
equal to `contextSize`. With the default 512, every pair above 512 tokens
fails with `input (N tokens) is too large to process`. With `local_gpu` each embedded input is
one chunk, so `embeddingContextTokens` only needs to cover `chunkSize`.

### The GGUF

The file must come from a conversion through llama.cpp's reranker path: it
carries the `cls.output.weight` tensor and a `tokenizer.chat_template.rerank`
metadata key. A plain causal-LM Qwen3-Reranker conversion has no classifier
head and cannot rerank. `giladgd/Qwen3-Reranker-4B-GGUF` is verified working.

llama-server applies that template itself, so client-side templating stays off
(`reranker.applyQwen3Template = false`). Turning it on wraps every pair twice
and flattens the score spread.

### First start and verification

The download runs at boot, independently of the socket proxy, but the first
one takes a while. Watch it, then exercise the endpoint:

```sh
sudo journalctl -fu gpt-researcher-reranker-model
sudo systemctl start gpt-researcher-reranker
sudo journalctl -fu gpt-researcher-reranker
```

```sh
curl http://127.0.1.1:20821/health
curl -X POST http://127.0.1.1:20821/v1/rerank -H 'Content-Type: application/json' \
  -d '{"model":"Qwen/Qwen3-Reranker-4B","query":"capital of France","documents":["Paris is the capital of France.","Bananas are yellow."],"top_n":2}'
nvidia-smi                                # or rocm-smi --showmemuse
curl http://127.0.0.1:11434/api/ps        # both models resident at once
```

A rerank request that fails logs a warning and the run continues in embedding
order:

```sh
sudo journalctl -fu podman-gpt-researcher-api | grep -i rerank
```

Known limits:

- `rocm.gfxOverride` cannot bridge a different ISA; it only helps a card that
  can pass as one `llama-cpp-rocm` already covers.
- The server holds its VRAM until the unit stops:
  `sudo systemctl stop gpt-researcher-reranker` before gaming or loading a
  large local LLM.
- Changing `modelUrl` downloads the new file on the next boot; the old GGUF
  stays in `/var/lib/gpt-researcher/reranker` until you delete it.

## Usage

Open the UI and submit a research query:

```sh
xdg-open https://gpt-researcher.wochap.local
```

The UI talks to the FastAPI backend at
<https://gpt-researcher-api.wochap.local>; both services start lazily on the
first request, so the first open can take a while.

GPT Researcher keeps SearxNG as its search retriever and sends the pages it
finds to the local Firecrawl service for scraping.
