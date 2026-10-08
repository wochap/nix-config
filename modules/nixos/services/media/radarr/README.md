# Radarr

Movie manager. Same role as Sonarr, for movies: imports from `/data/torrents/movies` into `/data/media/movies` by hardlink. Rootless image, runs read-only as the media user.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21111` | This host |
| `https://radarr.wochap.local` | This host, only with `services.radarr.proxy = true` |
| `http://media-radarr:7878` | Other containers |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: qBittorrent (`media-qbittorrent:8080`, downloads), Prowlarr (pushes indexers).
- Used by: Seerr (sends requests), Prowlarr (syncs indexers), Bazarr (reads the library), Jellyfin (reads the files).

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) first.

### A) Without declarative

1. Open `http://127.0.1.1:21111` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
2. Go to Settings › Media Management:
   - Select **Show Advanced**. Under Importing, check that "Use Hardlinks instead of Copy" is on.
   - Under Root Folders, add `/data/media/movies`.
   - Optional: turn on Rename Movies.
3. Go to Settings › Download Clients › **+** › qBittorrent:
   - Host `media-qbittorrent` (`media-vpn` with the VPN), Port `8080`.
   - Username and Password: empty, because qBittorrent bypasses auth for `10.90.0.0/24`.
   - Category `movies`.

   Select **Test**, then **Save**.
4. Optional: Settings › Profiles. The default `HD-1080p` works for a start.
5. Copy the API key from Settings › General › Security. Prowlarr, Seerr and Bazarr need it.

Do not add indexers here. Prowlarr pushes them.

### B) With declarative

The API key comes from SOPS (`RADARR__AUTH__APIKEY`), so Prowlarr and Seerr get it without copying. Automatic (`media-radarr-config`, v3 API), when missing:

- Step 1: login with `admin.username` and the SOPS password.
- Step 2: root folder. Warns in the journal when hardlinks are off, but does not change the setting.
- Step 3: download client. An existing client on `media-qbittorrent` or `media-vpn` follows the VPN setting.

Manual: optional renaming and profiles, and copying the key into Bazarr.

## Troubleshooting

- Logs: `journalctl -u podman-media-radarr`, `journalctl -u media-radarr-config`.
- Imports copy instead of hardlink: `/data/torrents` and `/data/media` must be on one filesystem, and the hardlink setting must be on.
- No search results: check Settings › Indexers. Fix indexers in Prowlarr, not here.

## Reset / backup

State: `/var/lib/media-server/radarr` (database, `config.xml`). Back up `radarr.db` and `config.xml`, or use System › Backup.

To reset: `sudo systemctl stop podman-media-radarr`, delete the directory, `sudo systemctl start podman-media-radarr`. With declarative, the login, root folder, download client and API key come back. Prowlarr pushes indexers again. The movie list is lost.

## Upgrade

Option `images.radarr`, image `ghcr.io/home-operations/radarr`. [Release notes](https://github.com/Radarr/Radarr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
