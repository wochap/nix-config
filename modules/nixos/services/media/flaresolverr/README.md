# FlareSolverr

Proxy that solves Cloudflare challenges with a headless Chromium. Prowlarr sends requests for Cloudflare-protected indexers (1337x, some YTS mirrors, ...) through it. No UI, no state, no mounts.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21161` | This host (API only, for testing) |
| `http://media-flaresolverr:8191` | Other containers |

No vhost or LAN URL: there is no UI.

## Depends on / used by

- Depends on: nothing. Indexer sites on the internet.
- Used by: Prowlarr, as an indexer proxy. Only indexers that share the proxy's tag go through it.

## Setup

Set up [Prowlarr](../prowlarr/README.md#setup) first.

### A) Without declarative

1. In Prowlarr, go to Settings › Indexers › **+** › FlareSolverr.
2. Set Name `FlareSolverr`, Tags `flaresolverr`, Host `http://media-flaresolverr:8191/`. Select **Test**, then **Save**.
3. Go to Indexers, edit each Cloudflare-protected indexer (or add it now), add the tag `flaresolverr`, **Test**, **Save**.

### B) With declarative

Automatic (`media-prowlarr-config`, v1 API): the tag `flaresolverr` and the FlareSolverr proxy with that tag (step 1–2). An existing proxy is left as is.

Manual: step 3, tag the indexers that need it.

## Troubleshooting

- Logs: `journalctl -u podman-media-flaresolverr`. For more detail, set `LOG_LEVEL=debug` in `flaresolverr/default.nix`.
- Check it answers: `curl -s http://127.0.1.1:21161/` returns `FlareSolverr is ready!`.
- Solve a page by hand:

  ```sh
  curl -s http://127.0.1.1:21161/v1 -H 'Content-Type: application/json' \
    -d '{"cmd":"request.get","url":"https://1337x.to","maxTimeout":60000}' | jq '.status, .message'
  ```

- An indexer still fails behind Cloudflare: check it has the `flaresolverr` tag. Cloudflare changes its challenges often; upgrade the image. Some challenges (Turnstile with interaction) FlareSolverr cannot solve at all.
- With the qBittorrent VPN, FlareSolverr still uses the host's connection, not the tunnel.

## Reset / backup

Stateless: nothing to back up. Restart: `sudo systemctl restart podman-media-flaresolverr`.

## Upgrade

Option `images.flaresolverr`, image `ghcr.io/flaresolverr/flaresolverr`. [Release notes](https://github.com/FlareSolverr/FlareSolverr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
