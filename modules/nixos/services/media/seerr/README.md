# Seerr

Request portal (formerly Jellyseerr). Users sign in with their Jellyfin account, request movies/series, admins approve; approved requests go to Radarr/Sonarr. Exposed at `https://seerr.wochap.local`. Container `media-seerr`, port 5055. No media mounts; it only talks to Jellyfin, Sonarr and Radarr over the `media` network.

State: `/var/lib/media-server/seerr`.

## Setup

Seerr runs in a container. It reaches Jellyfin, Radarr and Sonarr over the `media` network by container name, not through nginx. Inside the container, `*.wochap.local` and `127.0.1.1` point at the container itself.

Set up [Jellyfin](../jellyfin/README.md#setup), [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup) first. Seerr needs the Sonarr and Radarr API keys.

1. Open `https://seerr.wochap.local` on the host, and choose **Jellyfin**.
2. Sign In:
   - Jellyfin URL: `media-jellyfin`, Port `8096`, Use SSL off, URL Base empty.
   - Email, Username, Password: the Jellyfin admin account.
3. Configure Media Server: select **Sync Libraries**, and turn on Movies and Shows.
4. Configure Services: add one Radarr server and one Sonarr server.

   | Field | Radarr | Sonarr |
   |---|---|---|
   | Default Server | on | on |
   | 4K Server | off | off |
   | Server Name | `Radarr` | `Sonarr` |
   | Hostname or IP Address | `media-radarr` | `media-sonarr` |
   | Port | `7878` | `8989` |
   | Use SSL | off | off |
   | API Key | Radarr's key | Sonarr's key |
   | URL Base | empty | empty |

   Select **Test**. That fills the dropdowns. Then set:
   - Quality Profile: for example `HD-1080p`.
   - Root Folder: `/data/media/movies` for Radarr, `/data/media/series` for Sonarr.
   - Minimum Availability (Radarr only): `Released`.
   - Season Folders (Sonarr only): on.
   - Enable Scan and Enable Automatic Search: on.
   - External URL: empty. Radarr and Sonarr are admin-only.

   If Radarr and Sonarr are not ready yet, select **Finish Setup**, and add them later under Settings › Services.
5. Go to Settings › Jellyfin, and set External URL to `https://jellyfin.gdesktop.geanmar.com`. Seerr uses this URL for the links it shows to users.
6. Go to Settings › General, and set Application URL to `https://seerr.gdesktop.geanmar.com`.
7. Go to Users › **Import Jellyfin Users**. Under Settings › Users › Default Permissions, choose whether requests need approval. The Auto-Approve permissions skip approval.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/seerr-team/seerr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/seerr-team/seerr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/seerr` is kept. Read the upstream release notes first for breaking changes.
