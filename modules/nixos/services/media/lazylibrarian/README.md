# LazyLibrarian

Ebook and audiobook acquisition. Searches indexers (pushed by Prowlarr), downloads through qBittorrent, and moves finished files to `/data/media/books/ingest` (Calibre-Web Automated) or `/data/media/audiobooks` (Audiobookshelf).

Only a LinuxServer.io (s6-overlay) image exists: the container starts as root with a minimal capability set, then drops to `PUID`/`PGID`. `ebook-convert` is not bundled; Calibre-Web Automated converts on ingest.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21151` | This host |
| `https://lazylibrarian.wochap.local` | This host, only with `services.lazylibrarian.proxy = true` |
| `http://media-lazylibrarian:5299` | Other containers |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: qBittorrent (`media-qbittorrent:8080`, downloads), Prowlarr (pushes indexers).
- Used by: Calibre-Web Automated (ingest folder), Audiobookshelf (audiobook folder), Prowlarr (syncs indexers with its API key).

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) and [Prowlarr](../prowlarr/README.md#setup) first.

### A) Without declarative

1. Open `http://127.0.1.1:21151` on the host.
2. Go to Config › Interface, and set a username and password.
3. Go to Config › Downloaders, and turn on qBittorrent:
   - Host `media-qbittorrent` (`media-vpn` with the VPN), Port `8080`.
   - Label `books` for ebooks, `audiobooks` for audiobooks.
4. Go to Config › Importing:
   - eBook destination folder: `/data/media/books/ingest`.
   - AudioBook destination folder: `/data/media/audiobooks`.
   - Download directory: `/data/torrents/books`.
5. Go to Config › Interface, turn on the API, generate a key, and save.
6. Add LazyLibrarian as an app in Prowlarr ([Prowlarr](../prowlarr/README.md#a-without-declarative), step 2). Alternative: under Config › Providers, add Torznab feeds `http://media-prowlarr:9696/<id>/api` with Prowlarr's API key.

### B) With declarative

Automatic: only step 6, done by `media-prowlarr-config`. The API key can be preset only by editing `config.ini`, and `writeCFG` takes undocumented config names, so the layer does not touch LazyLibrarian.

Manual: steps 1–5. Then put the key from step 5 in the SOPS secret `apiKeys.lazylibrarian`, rebuild, and run `sudo systemctl restart media-prowlarr-config` ([Secrets](../README.md#secrets), step 4). After switching the qBittorrent VPN, change the host in step 3 by hand.

## Troubleshooting

- Logs: `journalctl -u podman-media-lazylibrarian`.
- No indexers: check `journalctl -u media-prowlarr-config` for `LazyLibrarian app not added`. The SOPS key must match Config › Interface.
- Downloads finish but never import: check that the download directory is `/data/torrents/books` and the label matches the qBittorrent category.

## Reset / backup

State: `/var/lib/media-server/lazylibrarian` (`config.ini`, database). Back up the directory.

To reset: `sudo systemctl stop podman-media-lazylibrarian`, delete the directory, `sudo systemctl start podman-media-lazylibrarian`. All settings are lost; redo steps 1–5. The new instance has a new API key: update SOPS, and delete the stale LazyLibrarian app in Prowlarr › Settings › Apps before you restart `media-prowlarr-config`.

## Upgrade

Option `images.lazylibrarian`, image `lscr.io/linuxserver/lazylibrarian`. [Release notes](https://gitlab.com/LazyLibrarian/LazyLibrarian/-/commits/master). LinuxServer tags are `version-<short sha>`. Find the current one with `skopeo inspect docker://lscr.io/linuxserver/lazylibrarian:latest | jq .Labels`, then pin that tag and its digest. Procedure: [Upgrading images](../README.md#upgrading-images).
