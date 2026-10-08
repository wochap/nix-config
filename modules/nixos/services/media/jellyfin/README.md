# Jellyfin

Media server. Streams the movies and series in `/data/media/{movies,series}` (read-only) to browsers and mobile/TV apps.

## URLs

| URL | Reachable from |
|---|---|
| `https://jellyfin.wochap.local` | This host |
| `http://127.0.1.1:21001` | This host |
| `https://jellyfin.<web-gate.domain>`, e.g. `https://jellyfin.gdesktop.geanmar.com` | LAN devices, when `web-proxies.jellyfin.expose.enable` |
| `http://media-jellyfin:8096` | Other containers |

## Depends on / used by

- Depends on: Sonarr and Radarr fill its library folders. No network dependency.
- Used by: Seerr (sign-in, library sync, through `media-jellyfin:8096`).

## Setup

Hardware transcoding: `services.jellyfin.hardwareAcceleration = "vaapi"` passes the render nodes in `vaapiDevices` (default `/dev/dri/renderD128`) and adds the host `video`/`render` groups. `"nvidia"` uses the CDI device from nvidia-container-toolkit.

### A) Without declarative

1. Open `https://jellyfin.wochap.local` on the host.
2. In the wizard, choose the language and create the admin user.
3. Add the libraries:

   | Content type | Folder |
   |---|---|
   | Movies | `/data/media/movies` |
   | Shows | `/data/media/series` |

4. Finish the wizard, and sign in.
5. Go to Dashboard › Playback › Transcoding:
   - `vaapi`: Hardware acceleration `Video Acceleration API (VAAPI)`, device `/dev/dri/renderD128`.
   - `nvidia`: `Nvidia NVENC`.

   Turn on the codecs the GPU decodes, and save.
6. Go to Dashboard › Users, and create one user per household member. Seerr signs people in with these accounts.

### B) With declarative

Automatic (`media-jellyfin-config`, Jellyfin OpenAPI at `/api-docs/openapi.json`):

- Steps 2 and 4, while the wizard is not completed: creates the admin `admin.username` with the SOPS password, and completes the wizard. Language and metadata keep Jellyfin's defaults.
- Step 3, signed in as that admin: adds each library whose folder no library uses yet.
- Step 5, only the backend: sets `vaapi` (first of `vaapiDevices`) or `nvenc` while hardware acceleration is `none`.

Manual: the codecs in step 5, and step 6.

On a server set up by hand with another login, the admin sign-in fails, and the unit leaves libraries and transcoding alone.

## Mobile/TV clients

Install the Jellyfin app (Android, iOS, Android TV, webOS, ...), or Findroid or Swiftfin. Server address: the LAN URL, for example `https://jellyfin.gdesktop.geanmar.com`. Sign in with the user's own Jellyfin account. The LAN vhost has no web-gate, because these apps cannot complete it.

## Troubleshooting

- Logs: `journalctl -u podman-media-jellyfin`, `journalctl -u media-jellyfin-config`.
- Playback stutters or transcodes on the CPU: check Dashboard › Playback › Transcoding, and that `/dev/dri/renderD128` is the right GPU (`ls -l /dev/dri/by-path`).
- New files do not appear: Dashboard › Libraries › Scan All Libraries.

## Reset / backup

State: `/var/lib/media-server/jellyfin/{config,cache}`. Back up `config` (users, watch history, settings). `cache` can be dropped.

To reset: `sudo systemctl stop podman-media-jellyfin`, delete the directory, `sudo systemctl start podman-media-jellyfin`. With declarative, the wizard, libraries and backend come back. Users and watch history are lost. Seerr's Jellyfin sign-in then breaks: reset Seerr too.

## Upgrade

Option `images.jellyfin`, image `docker.io/jellyfin/jellyfin`. [Release notes](https://github.com/jellyfin/jellyfin/releases). Jellyfin migrates its database on major upgrades and cannot downgrade, so back up `config` first. Procedure: [Upgrading images](../README.md#upgrading-images).
