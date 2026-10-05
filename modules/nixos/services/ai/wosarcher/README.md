# wosarcher

Self-hosted [wosarcher](https://github.com/wochap/wosarcher) research server
with its web UI at <https://wosarcher.wochap.local>. The image is built
locally from the `wosarcher` flake input and tagged with its revision.

## Setup

1. Enable the module and switch:

   ```nix
   _custom.services.ai.wosarcher.enable = true;
   ```

   The first switch builds the image, which pulls `node:24-slim`,
   `python:3.13-slim` and the uv image once.

2. Start the service. It is lazy, so open
   <https://wosarcher.wochap.local> once or run:

   ```sh
   sudo systemctl start podman-wosarcher
   ```

3. Set the admin password. Until then every API request returns
   `403 bad_host`. The server reloads `auth.json` when it changes, so no
   restart is needed:

   ```sh
   sudo podman exec -it --user 10001:10001 wosarcher wosarcher auth set-password
   ```

   Pass `--user 10001:10001` to every `podman exec`. Without it, podman fails
   with `unable to find user wosarcher: no matching entries in passwd file`.

   To keep the hash in SOPS instead, put `WOSARCHER_AUTH__PASSWORD_HASH`
   (from `wosarcher auth set-password --print`) in a file passed as
   `environmentFile`.

4. Check every provider. When the reranker is enabled, `score` reports a
   `ReadTimeout` until `reranker-model` has finished downloading the GGUF
   (`journalctl -fu reranker-model`):

   ```sh
   sudo podman exec --user 10001:10001 wosarcher wosarcher doctor
   ```

5. Log in at <https://wosarcher.wochap.local/#/new>.

No other secret is needed: the OmniRoute key reaches the container through
the `wosarcher.env` SOPS template.

## Profiles

Profiles are generated from this host's proxies: SearxNG, Firecrawl, Ollama
embeddings, and OmniRoute. They differ in how passages are picked and in the
LLM that plans and writes. Each scorer variant below exists once per entry of
`llms`:

| Profile | Prefilter | Scorer | Notes |
|---|---|---|---|
| `embeddings-rerank` | Ollama embeddings | shared llama-server reranker ([../reranker](../reranker/README.md)) | Default without `jev.enable`; offline, no key. Scores with BM25 when `_custom.services.ai.reranker.enable` is off. |
| `embeddings-jev` | Ollama embeddings | [TypeSafe Jev](https://api.typesafe.ai/v1) | gdesktop's default. |
| `bm25-jev` | BM25 | Jev | No embedding step, the fastest. |
| `bm25-jev-wide` | BM25, 100 candidates per sub-query | Jev, score at least 2.0, up to 25 per sub-query | Favours coverage over speed; not yet evaluated. Use it with Standard depth, because the other depth presets set their own passages per query. |

`jev.enable = true` adds the three Jev variants. Jev sends every scored chunk
to TypeSafe. The API key comes from `personal-typesafe-api-key` in
`secrets-sops/personal.yaml` as `WOSARCHER_SCORE__API_KEY`. In a replay of 9
questions, Jev was judged at least as precise as the local reranker, with a
2-4 s score stage instead of 26-40 s on the GPU (and no embedding step for
`bm25-jev`).

The LLMs come from `llms`, with limits from the shared model presets in
[../model-presets.nix](../model-presets.nix):

| LLM | OmniRoute combo | Preset | `context_window` | `max_output_tokens` | `timeout` | `research.gap_context_tokens` |
|---|---|---|---|---|---|---|
| `deepseek` | `research-smart` | `deepseek-v4-flash` | 1048576 | 131072 | 300 | 200000 |
| `free` | `desktop-free` | `qwen3-5-9b-local` | 32768 | 8192 | 600 | 4000 |

The `defaultLlm` (`deepseek`) keeps the plain profile name, such as
`embeddings-jev`. Every other LLM adds a suffix, such as `embeddings-jev-free`.
`context_window` is the model's whole window, prompt plus completion:
wosarcher subtracts its prompt reserve and the report's output allowance
itself. `max_output_tokens` is the preset's limit, at most half the window and
at most 131072, the largest limit proven through OmniRoute. `desktop-free`
can fall back to the local 32k `gdesktop-qwen3.5:9b`, so it is sized for that
model.

Pick the default with `profile`, or pick one per run in the UI's options.
Override single keys per host and profile, or add an LLM:

```nix
_custom.services.ai.wosarcher.profiles.embeddings-jev.llm.model = "research-fast";
_custom.services.ai.wosarcher.llms.gemma = {
  model = "gemma-combo";
  preset = "gemma4-31b";
};
```

Declared profiles are copied to `/var/lib/wosarcher/config/wosarcher/profiles`
on every start. Hand-made profiles in that directory are kept.

## Update

```sh
nix flake update wosarcher
nixos-rebuild switch
```

## Check

```sh
sudo podman exec --user 10001:10001 wosarcher wosarcher doctor
sudo podman exec --user 10001:10001 wosarcher wosarcher run "test" --until select
```

## Debugging

wosarcher has no pipeline log of its own. Each run records its stage events
in `events.jsonl` inside its run directory; the container journal only holds
HTTP access lines, warnings and tracebacks.

```sh
# Runs, newest last
sudo ls /var/lib/wosarcher/share/wosarcher/runs

# Follow a run's stage events
sudo tail -f /var/lib/wosarcher/share/wosarcher/runs/<run-id>/events.jsonl \
  | jq -c '{ts, stage, type, data}'

# Why a run failed
sudo jq -r 'select(.type == "run.failed") | .data.stage, .data.error' \
  /var/lib/wosarcher/share/wosarcher/runs/<run-id>/events.jsonl

# Server log
journalctl -fu podman-wosarcher

# Resolved configuration of the active profile
sudo podman exec --user 10001:10001 wosarcher wosarcher profile show
```

Each run directory also keeps every stage's output (`plan.json`,
`hits.jsonl`, `pages.jsonl`, `chunks.jsonl`, `scores.jsonl`, `context.json`,
`report.md`, `costs.json`), so a failing stage can be inspected with `jq`.
