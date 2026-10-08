# Prowlarr

Indexer manager: one place to configure torrent indexers, which it syncs to Sonarr, Radarr and LazyLibrarian. Admin UI, loopback only (`127.0.1.1:21121`). Container `media-prowlarr`, port 9696. No media mounts.

State: `/var/lib/media-server/prowlarr`.

## Setup

Prowlarr is set up in two steps: indexers first, apps after Sonarr and Radarr exist.

1. Open `http://127.0.1.1:21121` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
2. Go to Indexers › Add Indexer. Search for the indexers you use, and fill in their settings:
   - Public indexers need no account.
   - Private indexers ask for credentials or an API key.

   Select **Test**, then **Save**. Some indexers sit behind a Cloudflare challenge and fail the test. Those need FlareSolverr, which this stack does not include.
3. Set up [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup). Copy their API keys.
4. Go to Settings › Apps › **+**. Add each app:

   | App | Prowlarr Server | App Server | API Key |
   |---|---|---|---|
   | Sonarr | `http://media-prowlarr:9696` | `http://media-sonarr:8989` | Sonarr's key |
   | Radarr | `http://media-prowlarr:9696` | `http://media-radarr:7878` | Radarr's key |
   | LazyLibrarian | `http://media-prowlarr:9696` | `http://media-lazylibrarian:5299` | LazyLibrarian's key |

   Keep Sync Level `Full Sync`. Select **Test**, then **Save**.
5. Prowlarr pushes its indexers to each app. Check in Sonarr › Settings › Indexers. Add or change indexers in Prowlarr only: Full Sync overwrites edits made in the apps.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/prowlarr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/prowlarr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/prowlarr` is kept. Read the upstream release notes first for breaking changes.
