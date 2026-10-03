# wosarcher

Self-hosted [wosarcher](https://github.com/wochap/wosarcher) research server
with its web UI at <https://wosarcher.wochap.local>. The image is built
locally from the `wosarcher` flake input and tagged with its revision.

## Setup

```nix
_custom.services.ai.wosarcher.enable = true;
```

Set the admin password once. The server reloads `auth.json` when it changes,
so no restart is needed:

```sh
sudo podman exec -it wosarcher wosarcher auth set-password
```

To keep the hash in SOPS instead, put `WOSARCHER_AUTH__PASSWORD_HASH` (from
`wosarcher auth set-password --print`) in a file passed as `environmentFile`.

## Profiles

The `nixos` profile is generated from this host's proxies: SearxNG,
Firecrawl, Ollama embeddings, OmniRoute (`research-smart`) and, when
`gptResearcher.reranker.enable` is set, the shared llama-server reranker
behind its lazy proxy. Without the reranker, scoring uses BM25.

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
sudo podman exec wosarcher wosarcher doctor
sudo podman exec wosarcher wosarcher run "test" --until select
```
