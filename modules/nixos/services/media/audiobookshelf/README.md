# Audiobookshelf

Audiobook and podcast library and player, with mobile apps. Serves `/data/media/audiobooks` read-only. The container listens on 13378, because the media user cannot bind the image default, port 80.

## URLs

| URL | Reachable from |
|---|---|
| `https://audiobookshelf.wochap.local` | This host |
| `http://127.0.1.1:21031` | This host |
| `https://audiobookshelf.<web-gate.domain>`, e.g. `https://audiobookshelf.gdesktop.geanmar.com` | LAN devices, when `web-gate.proxies.audiobookshelf.expose.enable` |
| `http://media-audiobookshelf:13378` | Other containers |

## Depends on / used by

- Depends on: LazyLibrarian fills the audiobook folder. No network dependency.
- Used by: listeners, in a browser or the mobile app.

## Setup

### A) Without declarative

1. Open `https://audiobookshelf.wochap.local` on the host, and create the root user.
2. Go to Settings › Libraries › Add Library. Media type `Audiobooks`, folder `/data/media/audiobooks`.
3. Go to Settings, and turn on the folder watcher. Books that [LazyLibrarian](../lazylibrarian/README.md#setup) drops then appear on their own.
4. Optional: under Settings › Users, add one user per listener.

### B) With declarative

Automatic: nothing. Do steps 1–4.

## Mobile/TV clients

Audiobookshelf app (Android, iOS). Server address: the LAN URL, for example `https://audiobookshelf.gdesktop.geanmar.com`. Sign in with the user's own account. The LAN vhost has no web-gate, because the app cannot complete it.

## Troubleshooting

- Logs: `journalctl -u podman-media-audiobookshelf`.
- New books do not appear: check that the folder watcher is on, or select Scan on the library.

## Reset / backup

State: `/var/lib/media-server/audiobookshelf/{config,metadata}`. Back up `config` (users, progress). `metadata` holds covers and cache.

To reset: `sudo systemctl stop podman-media-audiobookshelf`, delete the directory, `sudo systemctl start podman-media-audiobookshelf`. Redo steps 1–4. Listening progress is lost.

## Upgrade

Option `images.audiobookshelf`, image `ghcr.io/advplyr/audiobookshelf`. [Release notes](https://github.com/advplyr/audiobookshelf/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
