# qBittorrent

Download client. Writes to `/data/torrents/<category>`; the *arr apps hardlink from there, so keep seeding without duplicating files. Admin UI, loopback only (`127.0.1.1:21131`). Container `media-qbittorrent`, web UI port 8080.

## Setup

Do this first. Sonarr, Radarr and LazyLibrarian send their downloads here.

With `declarative.enable` ([Declarative configuration](../README.md#declarative-configuration)), `media-qbittorrent-config` does all of it through the documented WebUI API:

- Auth bypass for `10.90.0.0/24` (the `media` network), appended to the whitelist; other subnets stay. The unit itself gets in through the image's default whitelist (`10.0.0.0/8`; host requests arrive from the `media` gateway), or, when the bypass is off, by logging in with the shared admin.
- Login: `admin.username` and the SOPS password, set once. The API cannot tell whether a password exists, so the unit sets it when the shared login does not work yet and then writes a marker in `/var/lib/media-declarative`; a password changed later in the UI is kept. A password set by hand before the first run is replaced.
- Default Save Path `/data/torrents` with Automatic Torrent Management, while the save path is still the image's `/config/Downloads`.
- The four categories below, when missing. Existing categories are not changed.

Without it:

1. Open `http://127.0.1.1:21131` on the host. The user is `admin`. qBittorrent prints a temporary password at first start:

   ```sh
   journalctl -u podman-media-qbittorrent | grep -i password
   ```

2. Go to Tools › Options › Web UI › Authentication:
   - Set your own username and password.
   - Tick "Bypass authentication for clients in whitelisted IP subnets", and enter `10.90.0.0/24` (the `media` network). The other containers then connect without credentials.
3. Go to Tools › Options › Downloads:
   - Default Torrent Management Mode: `Automatic`. Each category then uses its own save path.
   - Default Save Path: `/data/torrents`.
4. In the left panel, right-click CATEGORIES › Add category. Add these four:

   | Category | Save path |
   |---|---|
   | `movies` | `/data/torrents/movies` |
   | `series` | `/data/torrents/series` |
   | `books` | `/data/torrents/books` |
   | `audiobooks` | `/data/torrents/audiobooks` |

Other containers reach qBittorrent at host `media-qbittorrent`, port `8080`. With the VPN enabled, use host `media-vpn` instead (see below).

## VPN (optional)

`services.qbittorrent.vpn.enable = true` starts a gluetun sidecar (`media-vpn`, image `docker.io/qmcgaw/gluetun`). qBittorrent then runs with `--network=container:media-vpn`: it has no interface of its own, so all its traffic goes through the tunnel and gluetun's firewall. Other containers reach the web UI at `media-vpn:8080`; the loopback port is published by gluetun. qBittorrent is `BindsTo` gluetun and restarts with it.

Configuration is split:

- `vpn.environment`: non-secret gluetun variables (`VPN_SERVICE_PROVIDER`, `VPN_TYPE`, `SERVER_COUNTRIES`, ...).
- `vpn.sopsKey` (default `local-media-vpn-env`): key in `secrets-sops/local.yaml` whose value is an env file with the secrets, for example:

  ```
  WIREGUARD_PRIVATE_KEY=...
  WIREGUARD_ADDRESSES=10.x.y.z/32
  ```

  Add the key before enabling; sops-nix checks it at build time.
- `vpn.environmentFiles`, `vpn.extraOptions`: escape hatches.

To swap gluetun for another VPN container, change `images.gluetun` and adjust `vpn.environment`; the namespace sharing does not depend on gluetun specifics.

State: `/var/lib/media-server/qbittorrent`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/qbittorrent | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/qbittorrent:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/qbittorrent` is kept. Read the upstream release notes first for breaking changes.
