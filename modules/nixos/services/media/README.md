# Media stack

Podman containers behind `_custom.services.media`. One enable option per service, shared `media` user (2000:2000), shared `media` podman network with DNS, pinned images in one `images` block. Per-service README in each subdirectory covers purpose and upgrades.

## Layout

| Host | Container | Purpose |
|---|---|---|
| `dataRoot/torrents/{movies,series,books,audiobooks}` | `/data/torrents/...` | qBittorrent categories |
| `dataRoot/media/{movies,series}` | `/data/media/...` | Sonarr/Radarr libraries, Jellyfin reads |
| `dataRoot/media/books/ingest` | `/data/media/books/ingest` | LazyLibrarian drops ebooks, CWA consumes |
| `dataRoot/media/books/library` | `/data/media/books/library` | Calibre library |
| `dataRoot/media/audiobooks` | `/data/media/audiobooks` | LazyLibrarian drops, Audiobookshelf watches |
| `/var/lib/media-server/<svc>` | `/config` | per-service state |

Every container sees the same paths under `/data`, so no remote path mappings are needed and imports from torrents to media are hardlinks.

## Ports (on 127.0.1.1)

User-facing, with nginx vhost `<name>.wochap.local`: jellyfin 21001, seerr 21011, calibre-web 21021, audiobookshelf 21031.
Admin, loopback only: sonarr 21101, radarr 21111, prowlarr 21121, qbittorrent 21131, bazarr 21141, lazylibrarian 21151. Set `services.<svc>.proxy = true` for a vhost.

Container-to-container addresses: `media-<name>:<port>` (jellyfin 8096, seerr 5055, sonarr 8989, radarr 7878, prowlarr 9696, qbittorrent 8080, bazarr 6767, lazylibrarian 5299, calibre-web 8083, audiobookshelf 13378). With the VPN enabled qBittorrent is reached as `media-vpn:8080`.

## Setup

Order matters: each step produces an API key or a folder that a later step uses. Each service README has a Setup section with the details.

Admin UIs (`127.0.1.1:<port>`) open only on the host. User-facing apps also open on the LAN at `https://<name>.<web-gate.domain>` when their proxy is exposed (see `../web-proxies/README.md`). Between containers, always use the container name, for example `media-sonarr:8989`.

1. [qBittorrent](qbittorrent/README.md#setup): password, auth bypass for the `media` network, download categories.
2. [Prowlarr](prowlarr/README.md#setup), steps 1–2: admin user and indexers.
3. [Sonarr](sonarr/README.md#setup): root folder, download client, API key.
4. [Radarr](radarr/README.md#setup): same as Sonarr, for movies.
5. [Prowlarr](prowlarr/README.md#setup), steps 3–5: connect Sonarr, Radarr and LazyLibrarian, and sync indexers.
6. [Bazarr](bazarr/README.md#setup): languages, subtitle providers, Sonarr and Radarr.
7. [Jellyfin](jellyfin/README.md#setup): admin user, libraries, hardware transcoding, users.
8. [Seerr](seerr/README.md#setup): Jellyfin sign-in, Radarr and Sonarr, external URLs, users.
9. [Calibre-Web Automated](calibre-web/README.md#setup): password and library.
10. [Audiobookshelf](audiobookshelf/README.md#setup): root user, library, folder watcher.
11. [LazyLibrarian](lazylibrarian/README.md#setup): downloader, import folders, Prowlarr.
12. Optional, later: [qBittorrent VPN](qbittorrent/README.md#vpn-optional). After enabling it, change the qBittorrent host in Sonarr, Radarr and LazyLibrarian from `media-qbittorrent` to `media-vpn`. To see the tunnel IP, run `journalctl -u podman-media-vpn`.

## Notes

- Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent use rootless home-operations images with `--read-only`. Jellyfin, Seerr, Audiobookshelf, gluetun are upstream images. LazyLibrarian and Calibre-Web Automated only ship as s6/PUID images; they start as root with the minimal capability set to drop privileges.
- The desktop user is added to group `media`; containers run with `UMASK=002` so library files stay group-writable.
- `nixos-rebuild build` cannot run in a clone without the git-crypt key (`secrets-git-crypt/nix/default.nix` fails to parse). This is unrelated to the stack.
