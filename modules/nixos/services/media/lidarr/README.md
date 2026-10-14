# Lidarr

Music manager. Follows artists, searches indexers (pushed by Prowlarr), sends grabs to qBittorrent, and imports finished downloads from `/data/torrents/music` into `/data/media/music` by hardlink. Also imports what [Soularr](../soularr/README.md) fetches from Soulseek into `/data/soulseek/downloads`. Rootless image, runs read-only as the media user.

Lidarr looks artists and albums up through its own metadata server (built on MusicBrainz). When that server is down, adding artists and matching imports fail until it is back. Nothing local can fix that.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21171` | This host |
| `https://lidarr.wochap.local` | This host, only with `services.lidarr.proxy = true` |
| `http://media-lidarr:8686` | Other containers |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: qBittorrent (`media-qbittorrent:8080`, downloads), Prowlarr (pushes indexers).
- Used by: Prowlarr (syncs indexers), Soularr (reads the wanted list, triggers imports), Navidrome (reads the files).

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) first.

### A) Without declarative

1. Open `http://127.0.1.1:21171` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
2. Go to Settings › Media Management:
   - Select **Show Advanced**. Under Importing, check that "Use Hardlinks instead of Copy" is on.
   - Under Root Folders, add `/data/media/music`, name `Music`, with the default quality and metadata profiles.
   - Optional: turn on Rename Tracks.
3. Go to Settings › Download Clients › **+** › qBittorrent:
   - Host `media-qbittorrent` (`media-vpn` with the VPN), Port `8080`.
   - Username and Password: empty, because qBittorrent bypasses auth for `10.90.0.0/24`.
   - Category `music`.

   Select **Test**, then **Save**.
4. Optional: Settings › Profiles. Metadata profile `Standard` grabs albums only; add EPs or singles there if you want them.
5. Copy the API key from Settings › General › Security. Prowlarr and Soularr need it.

Do not add indexers here. Prowlarr pushes them.

### B) With declarative

The API key comes from SOPS (`LIDARR__AUTH__APIKEY`), so Prowlarr and Soularr get it without copying. Automatic (`media-lidarr-config`, v1 API, same script as Sonarr and Radarr), when missing:

- Step 1: login with `admin.username` and the SOPS password.
- Step 2: root folder `/data/media/music` named `Music`, with the first quality profile and the first metadata profile other than `None`. Warns in the journal when hardlinks are off.
- Step 3: download client. An existing client on `media-qbittorrent` or `media-vpn` follows the VPN setting.

Manual: optional renaming and profiles.

## Troubleshooting

- Logs: `journalctl -u podman-media-lidarr`, `journalctl -u media-lidarr-config`.
- Adding an artist hangs or fails: usually the metadata server. Check System › Status, and the Lidarr status page or issue tracker.
- No search results: few public trackers carry music. Fix indexers in Prowlarr; Soularr covers the rest from Soulseek.
- Imports copy instead of hardlink: `/data/torrents` and `/data/media` must be on one filesystem.

## Reset / backup

State: `/var/lib/media-server/lidarr` (database, `config.xml`). Back up `lidarr.db` and `config.xml`, or use System › Backup.

To reset: `sudo systemctl stop podman-media-lidarr`, delete the directory, `sudo systemctl start podman-media-lidarr`. With declarative, the login, root folder, download client and API key come back. Prowlarr pushes indexers again. The artist list is lost.

## Upgrade

Option `images.lidarr`, image `ghcr.io/home-operations/lidarr`. [Release notes](https://github.com/Lidarr/Lidarr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
