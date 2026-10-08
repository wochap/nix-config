# Sonarr

Series manager: searches indexers (via Prowlarr), sends grabs to qBittorrent, imports finished downloads from `/data/torrents` into `/data/media/series` by hardlink. Admin UI, loopback only (`127.0.1.1:21101`), no nginx vhost unless `services.sonarr.proxy = true`. Container `media-sonarr`, port 8989.

Rootless home-operations image, runs read-only as the media user.

State: `/var/lib/media-server/sonarr`.

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) first.

1. Open `http://127.0.1.1:21101` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
2. Go to Settings › Media Management:
   - Select **Show Advanced** at the top. Under Importing, check that "Use Hardlinks instead of Copy" is on.
   - Under Root Folders, select **Add Root Folder**, and choose `/data/media/series`.
   - Optional: turn on Rename Episodes for clean file names.
3. Go to Settings › Download Clients › **+** › qBittorrent:
   - Host: `media-qbittorrent` (`media-vpn` with the VPN enabled)
   - Port: `8080`
   - Username and Password: leave empty when qBittorrent bypasses auth for `10.90.0.0/24`. Otherwise use the qBittorrent login.
   - Category: `series`

   Select **Test**, then **Save**.
4. Go to Settings › General › Security, and copy the API Key. [Prowlarr](../prowlarr/README.md#setup), [Bazarr](../bazarr/README.md#setup) and [Seerr](../seerr/README.md#setup) need it.
5. Do not add indexers here. Prowlarr pushes them (Prowlarr setup, step 4).
6. Optional: Settings › Profiles. The default `HD-1080p` profile works for a start.

Files move from `/data/torrents/series` to `/data/media/series` as hardlinks, so qBittorrent keeps seeding without a second copy. Every container sees the same `/data` paths, so no Remote Path Mappings are needed.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/sonarr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/sonarr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/sonarr` is kept. Read the upstream release notes first for breaking changes.
