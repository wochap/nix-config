# wosarcher

Self-hosted [wosarcher](https://github.com/wochap/wosarcher) research server
with its web UI at <https://wosarcher.wochap.local>. It runs as the native
`wosarcher.service` from the `wosarcher` flake's NixOS module
(`services.wosarcher`), behind a lazy web-gate socket: the first request
starts it. Data lives in `/var/lib/wosarcher`, owned by `wosarcher:wosarcher`
(uid and gid 10001).

The daemon (`wosarcherd`) is the only process that holds secrets and reads
`/var/lib/wosarcher`. The module puts two commands on the system path:

- `wosarcher`, a client that talks to the daemon over
  `/run/wosarcher/api.sock` (mode 0660, group `wosarcher`). Members of the
  group run it without a login or a token; `_custom.globals.userName` is a
  member (log in again after the first switch). Members cannot read the data
  directory, `auth.json`, or any key.
- `wosarcherd`, for administration as the service user, for example
  `sudo -u wosarcher wosarcherd auth set-password`.

Provider keys reach the daemon as files: the generated profiles set
`llm.api_key_file` (and `score.api_key_file` with `jev.enable`) to SOPS
secrets owned by `wosarcher` with mode 0400. No key is in the Nix store or in
an environment file.

## Setup

1. Before the first start on a host that has data from an older install,
   make the existing files the service user's alone, once:

   ```sh
   sudo chown -R wosarcher:wosarcher /var/lib/wosarcher
   sudo find /var/lib/wosarcher -type d -exec chmod 0700 {} +
   sudo find /var/lib/wosarcher -type f -exec chmod 0600 {} +
   ```

2. Enable the module and switch:

   ```nix
   _custom.services.ai.wosarcher.enable = true;
   ```

3. Start the service. It is lazy: the web-gate socket and
   `wosarcher.socket` both start it on the first connection, so open
   <https://wosarcher.wochap.local> once, run any `wosarcher` command, or:

   ```sh
   sudo systemctl start wosarcher
   ```

4. Set the admin password. Until then every API request returns
   `403 bad_host`. The server reloads `auth.json` when it changes, so no
   restart is needed:

   ```sh
   sudo -u wosarcher wosarcherd auth set-password
   ```

   To keep the hash in SOPS instead, store the output of
   `wosarcherd auth set-password --print` as a sops secret and name it in
   `passwordHashSecret`; the daemon then reads it through
   `auth.password_hash_file`.

5. Check every provider. When the reranker is enabled, `score` reports a
   `ReadTimeout` until `reranker-model` has finished downloading the GGUF
   (`journalctl -fu reranker-model`):

   ```sh
   wosarcher doctor
   ```

6. Log in at <https://wosarcher.wochap.local/#/new>. Set how many runs
   execute at once in Settings, "Run slots".

No other secret is needed: the OmniRoute key (and the Jev key with
`jev.enable`) is a sops secret owned by `wosarcher` (mode 0400) that the
profiles name through `api_key_file`. The daemon reads it when a run starts,
so a rotated key needs no restart.

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
`secrets-sops/personal.yaml`, read through `score.api_key_file`. In a replay of 9
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

Push the wosarcher repository first; the flake input tracks GitHub.

```sh
nix flake update wosarcher
nixos-rebuild switch
```

A `wosarcher` command that prints exit status 69 means the daemon is not
reachable on `/run/wosarcher/api.sock`: check `systemctl status
wosarcher.socket wosarcher`.

## Check

```sh
wosarcher doctor
wosarcher run "test" --until select
```

## Debugging

wosarcher has no pipeline log of its own. Each run records its stage events
in `events.jsonl` inside its run directory; the service journal only holds
HTTP access lines, warnings and tracebacks.

```sh
# Runs, newest last
wosarcher runs

# Follow a run's stage events
wosarcher logs <run-id> --follow

# Why a run failed (the data directory is the service user's alone)
sudo jq -r 'select(.type == "run.failed") | .data.stage, .data.error' \
  /var/lib/wosarcher/share/wosarcher/runs/<run-id>/events.jsonl

# Server log
journalctl -fu wosarcher

# Resolved configuration of the active profile
wosarcher profile show
```

Each run directory also keeps every stage's output (`plan.json`,
`hits.jsonl`, `pages.jsonl`, `chunks.jsonl`, `scores.jsonl`, `context.json`,
`report.md`, `costs.json`), so a failing stage can be inspected with `jq`.
