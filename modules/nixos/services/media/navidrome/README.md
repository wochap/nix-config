# Navidrome

Music server with a web player and the Subsonic API, so phone and desktop music apps can stream from it. Serves `/data/media/music` read-only. Rootless image, runs read-only. State lives in `/config`: the image default `/data` is the shared media tree here.

## URLs

| URL | Reachable from |
|---|---|
| `https://navidrome.wochap.local` | This host |
| `http://127.0.1.1:21041` | This host |
| `https://navidrome.<web-gate.domain>`, e.g. `https://navidrome.gdesktop.geanmar.com` | LAN devices, when `web-gate.proxies.navidrome.expose.enable` |
| `http://media-navidrome:4533` | Other containers |

## Depends on / used by

- Depends on: Lidarr fills the music folder. No network dependency.
- Used by: listeners, in a browser or a Subsonic client.

## Setup

### A) Without declarative

1. Open `https://navidrome.wochap.local` on the host. The first visit asks for the admin user.
2. The library is `/data/media/music`, with no extra step. The file watcher picks up new albums, and a full scan runs every hour (`ND_SCANNER_SCHEDULE`). To scan now: the Activity icon, top right › Scan.
3. Optional: under Settings › Users, add one user per listener.
4. Optional, per user: Personal › ListenBrainz to scrobble. Last.fm also needs an API key (`ND_LASTFM_APIKEY`, `ND_LASTFM_SECRET`), which this module does not set.

### B) With declarative

Automatic: nothing. Navidrome has no documented way to create the first admin. Do steps 1–4.

## Clients

Any Subsonic client. Server address: the LAN URL, for example `https://navidrome.gdesktop.geanmar.com`, with the user's own login. The LAN vhost has no web-gate, because the apps cannot complete it.

- Android: Symfonium (paid, best), Tempus.
- iOS: Amperfy, play:Sub.
- Desktop: Feishin.

## Troubleshooting

- Logs: `journalctl -u podman-media-navidrome`.
- An album does not appear: check that Lidarr imported it into `/data/media/music`, then run a scan. Albums with wrong tags group oddly; fix them in Lidarr (Retag), not in Navidrome.

## Reset / backup

State: `/var/lib/media-server/navidrome` (`navidrome.db` with users, playlists, play counts, and the cache). Back up `navidrome.db`.

To reset: `sudo systemctl stop podman-media-navidrome`, delete the directory, `sudo systemctl start podman-media-navidrome`. Redo steps 1–4. Playlists and play counts are lost.

## Upgrade

Option `images.navidrome`, image `docker.io/deluan/navidrome`. [Release notes](https://github.com/navidrome/navidrome/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
