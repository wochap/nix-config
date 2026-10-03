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

The `nixos` profile is generated from this host's proxies: SearxNG,
Firecrawl, Ollama embeddings, OmniRoute (`research-smart`) and, when
`_custom.services.ai.reranker.enable` is set, the shared llama-server
reranker ([../reranker](../reranker/README.md)) behind its lazy proxy.
Without the reranker, scoring uses BM25.

`jev.enable = true` adds a `nixos-jev` profile: the `nixos` profile with
`score.provider = "jev"` ([TypeSafe Jev](https://api.typesafe.ai/v1),
calibrated 0-3 usefulness scores). It sends every scored chunk to TypeSafe,
so it is picked per run in the UI's options rather than made the default.
Set `profile = "nixos-jev"` to make it the default. The API key comes from
`personal-typesafe-api-key` in `secrets-sops/personal.yaml` as
`WOSARCHER_SCORE__API_KEY`. `nixos-jev` is built from the generated defaults,
so host overrides of `profiles.nixos` must be repeated under
`profiles.nixos-jev`.

Override single keys per host:

```nix
_custom.services.ai.wosarcher.profiles.nixos.llm.model = "research-fast";
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
