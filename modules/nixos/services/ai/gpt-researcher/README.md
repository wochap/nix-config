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
