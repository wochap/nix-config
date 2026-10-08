# Sonarr

Series manager: searches indexers (via Prowlarr), sends grabs to qBittorrent, imports finished downloads from `/data/torrents` into `/data/media/series` by hardlink. Admin UI, loopback only (`127.0.1.1:21101`), no nginx vhost unless `services.sonarr.proxy = true`. Container `media-sonarr`, port 8989.

Rootless home-operations image, runs read-only as the media user.

State: `/var/lib/media-server/sonarr`.

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) first.

With `declarative.enable` ([Declarative configuration](../README.md#declarative-configuration)), `media-sonarr-config` uses the documented v3 API to add, when missing:

- Login: Forms, `admin.username` and the SOPS password, while no user exists (`config/host`).
- Root folder `/data/media/series`.
- A qBittorrent download client: host `media-qbittorrent` (`media-vpn` with the VPN; an existing client on either name follows the VPN setting), port `8080`, no credentials, category `series`.

It warns in the journal when "Use Hardlinks instead of Copy" is off, but does not change it. The API key comes from SOPS through the documented `SONARR__AUTH__APIKEY` env var, so Prowlarr and Seerr get it without copying.

Manual:

1. Optional: Settings › Media Management › Rename Episodes for clean file names.
2. Optional: Settings › Profiles. The default `HD-1080p` profile works for a start.
3. Do not add indexers here. Prowlarr pushes them.
4. [Bazarr](../bazarr/README.md#setup) needs the API key: copy it from Settings › General › Security.

Without `declarative`, also:

5. Open `http://127.0.1.1:21101` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
6. Go to Settings › Media Management:
   - Select **Show Advanced** at the top. Under Importing, check that "Use Hardlinks instead of Copy" is on.
   - Under Root Folders, select **Add Root Folder**, and choose `/data/media/series`.
7. Go to Settings › Download Clients › **+** › qBittorrent:
   - Host: `media-qbittorrent` (`media-vpn` with the VPN enabled)
   - Port: `8080`
   - Username and Password: leave empty when qBittorrent bypasses auth for `10.90.0.0/24`. Otherwise use the qBittorrent login.
   - Category: `series`

   Select **Test**, then **Save**.
8. Go to Settings › General › Security, and copy the API Key. [Prowlarr](../prowlarr/README.md#setup) and [Seerr](../seerr/README.md#setup) need it.

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
