# Bazarr

Subtitle manager. Watches the Sonarr and Radarr libraries, and downloads subtitles next to the files in `/data/media/{movies,series}`. Rootless image, runs read-only.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21141` | This host |
| `https://bazarr.wochap.local` | This host, only with `services.bazarr.proxy = true` |
| `http://media-bazarr:6767` | Other containers |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: Sonarr (`media-sonarr:8989`) and Radarr (`media-radarr:7878`), with their API keys. Subtitle providers on the internet.
- Used by: Jellyfin plays the subtitle files it writes.

## Setup

Set up [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup) first.

### A) Without declarative

1. Open `http://127.0.1.1:21141` on the host. Go to Settings › General › Security, set Authentication to `Form`, choose a username and password, and save.
2. Go to Settings › Languages:
   - Add your languages to Languages Filter.
   - Under Language Profiles, select **Add New Profile**, and add the languages in order of preference.
   - Under Default Settings, turn on the profile for Series and for Movies.
3. Go to Settings › Providers, and add subtitle providers. Some need an account, for example OpenSubtitles.com.
4. Go to Settings › Sonarr. Turn it on, set Address `media-sonarr`, Port `8989`, and Sonarr's API key. Select **Test**, then **Save**.
5. Go to Settings › Radarr. Same, with `media-radarr` and port `7878`.

All containers see the same `/data` paths, so Path Mappings stay empty.

### B) With declarative

Automatic: nothing. Bazarr's settings endpoint is UI-internal (not in its API docs), and its API key cannot be preset. Do steps 1–5. The Sonarr and Radarr keys are the SOPS values.

## Troubleshooting

- Logs: `journalctl -u podman-media-bazarr`.
- No subtitles found: check provider accounts and limits under System › Providers.
- Sonarr/Radarr test fails after you reset them without declarative: they have new API keys. Paste the new key.

## Reset / backup

State: `/var/lib/media-server/bazarr` (database, `config/config.yaml`). Back up the directory, or use System › Backups.

To reset: `sudo systemctl stop podman-media-bazarr`, delete the directory, `sudo systemctl start podman-media-bazarr`. All settings are lost; redo steps 1–5. Subtitle files stay next to the media.

## Upgrade

Option `images.bazarr`, image `ghcr.io/home-operations/bazarr`. [Release notes](https://github.com/morpheus65535/bazarr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
