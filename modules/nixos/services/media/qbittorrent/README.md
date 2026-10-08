# qBittorrent

Download client. Writes to `/data/torrents/<category>`. Sonarr and Radarr hardlink from there, so qBittorrent keeps seeding without duplicate files. Rootless image, runs read-only.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21131` | This host |
| `https://qbittorrent.wochap.local` | This host, only with `services.qbittorrent.proxy = true` |
| `http://media-qbittorrent:8080` | Other containers. With the VPN: `http://media-vpn:8080`. |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: nothing in the stack. Optional gluetun sidecar `media-vpn`.
- Used by: Sonarr, Radarr and LazyLibrarian send downloads here, without credentials (auth bypass for the `media` subnet).

## Setup

Do this first.

### A) Without declarative

1. Open `http://127.0.1.1:21131` on the host. The user is `admin`. qBittorrent prints a temporary password at first start:

   ```sh
   journalctl -u podman-media-qbittorrent | grep -i password
   ```

2. Go to Tools › Options › Web UI › Authentication:
   - Set your own username and password.
   - Tick "Bypass authentication for clients in whitelisted IP subnets", and add `10.90.0.0/24` (the `media` network).
3. Go to Tools › Options › Downloads:
   - Default Torrent Management Mode: `Automatic`. Each category then uses its own save path.
   - Default Save Path: `/data/torrents`.
4. In the left panel, right-click CATEGORIES › Add category, and add:

   | Category | Save path |
   |---|---|
   | `movies` | `/data/torrents/movies` |
   | `series` | `/data/torrents/series` |
   | `books` | `/data/torrents/books` |
   | `audiobooks` | `/data/torrents/audiobooks` |

### B) With declarative

Automatic (`media-qbittorrent-config`, WebUI API), all four steps:

- Step 2 bypass: appends the `media` subnet to the whitelist. Other subnets stay.
- Step 2 login: `admin.username` and the SOPS password, set once. The API cannot tell whether a password exists, so the unit sets it while the shared login fails, then writes `/var/lib/media-declarative/qbittorrent-login`. A password changed later in the UI is kept. A password set by hand before the first run is replaced.
- Step 3, while the save path is still the image's `/config/Downloads`.
- Step 4, for missing categories. Existing categories are not changed.

Manual: nothing.

## VPN (optional)

`services.qbittorrent.vpn.enable = true` starts a gluetun sidecar (`media-vpn`). qBittorrent then runs with `--network=container:media-vpn`: it has no interface of its own, so all its traffic goes through the tunnel and gluetun's firewall. gluetun publishes the loopback port. qBittorrent is `BindsTo` gluetun and restarts with it.

- `vpn.environment`: non-secret gluetun variables (`VPN_SERVICE_PROVIDER`, `VPN_TYPE`, `SERVER_COUNTRIES`, ...). See the [gluetun wiki](https://github.com/qdm12/gluetun-wiki).
- `vpn.sopsKey` (default `local-media-vpn-env`): key in `secrets-sops/local.yaml` whose value is an env file with the secrets. Add it before you enable the VPN; sops-nix checks it at build time.

  ```
  WIREGUARD_PRIVATE_KEY=...
  WIREGUARD_ADDRESSES=10.x.y.z/32
  ```

- `vpn.environmentFiles`, `vpn.extraOptions`: escape hatches.

After a switch, the download client host must change from `media-qbittorrent` to `media-vpn` (or back). With declarative, Sonarr and Radarr follow on the next rebuild. Change LazyLibrarian by hand, and all apps without declarative. To see the tunnel IP: `journalctl -u podman-media-vpn`.

## Troubleshooting

- Logs: `journalctl -u podman-media-qbittorrent`, `journalctl -u media-qbittorrent-config`. VPN: `journalctl -u podman-media-vpn`.
- Sonarr/Radarr test fails with 401/403: the auth bypass misses `10.90.0.0/24`. Restart `media-qbittorrent-config`, or add it by hand.
- Lost the password with declarative: delete `/var/lib/media-declarative/qbittorrent-login`, then restart `media-qbittorrent-config`. This works only while the bypass still lets the unit in.

## Reset / backup

State: `/var/lib/media-server/qbittorrent` (settings, torrent list and resume data). Downloaded files stay in `dataRoot`.

To reset: `sudo systemctl stop podman-media-qbittorrent`, delete the directory and `/var/lib/media-declarative/qbittorrent-login`, then `sudo systemctl start podman-media-qbittorrent`. With declarative, all settings come back. The torrent list is lost; Sonarr and Radarr lose track of active downloads.

## Upgrade

Option `images.qbittorrent`, image `ghcr.io/home-operations/qbittorrent`. [Release notes](https://www.qbittorrent.org/news). VPN sidecar: option `images.gluetun`, image `docker.io/qmcgaw/gluetun`. Procedure: [Upgrading images](../README.md#upgrading-images).
