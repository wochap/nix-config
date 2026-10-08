# Seerr

Request portal (formerly Jellyseerr). Users sign in with their Jellyfin account and request movies or series. After approval, Seerr sends the request to Radarr or Sonarr. No media mounts.

## URLs

| URL | Reachable from |
|---|---|
| `https://seerr.wochap.local` | This host |
| `http://127.0.1.1:21011` | This host |
| `https://seerr.<web-gate.domain>`, e.g. `https://seerr.gdesktop.geanmar.com` | LAN devices, when `web-gate.proxies.seerr.expose.enable` |
| `http://media-seerr:5055` | Other containers |

Inside the container, `*.wochap.local` and `127.0.1.1` point at the container itself. Seerr must reach the other services by container name.

## Depends on / used by

- Depends on: Jellyfin (`media-jellyfin:8096`, sign-in and libraries), Radarr (`media-radarr:7878`), Sonarr (`media-sonarr:8989`), with their API keys.
- Used by: household members, in a browser.

## Setup

Set up [Jellyfin](../jellyfin/README.md#setup), [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup) first.

### A) Without declarative

1. Open `https://seerr.wochap.local` on the host, and choose **Jellyfin**.
2. Sign in:
   - Jellyfin URL `media-jellyfin`, Port `8096`, Use SSL off, URL Base empty.
   - Email, Username, Password: the Jellyfin admin account.
3. Configure Media Server: select **Sync Libraries**, and turn on Movies and Shows.
4. Configure Services: add one Radarr server and one Sonarr server.

   | Field | Radarr | Sonarr |
   |---|---|---|
   | Default Server | on | on |
   | 4K Server | off | off |
   | Server Name | `Radarr` | `Sonarr` |
   | Hostname or IP Address | `media-radarr` | `media-sonarr` |
   | Port | `7878` | `8989` |
   | Use SSL | off | off |
   | API Key | Radarr's key | Sonarr's key |
   | URL Base | empty | empty |

   Select **Test** to fill the dropdowns. Then set Quality Profile (for example `HD-1080p`), Root Folder (`/data/media/movies` or `/data/media/series`), Minimum Availability `Released` (Radarr), Season Folders on (Sonarr), Enable Scan and Enable Automatic Search on. Leave External URL empty.
5. Go to Settings › Jellyfin, and set External URL to the Jellyfin LAN URL, for example `https://jellyfin.gdesktop.geanmar.com`. Seerr links users there.
6. Go to Settings › General, and set Application URL to the Seerr LAN URL, for example `https://seerr.gdesktop.geanmar.com`.
7. Go to Users › **Import Jellyfin Users**. Under Settings › Users › Default Permissions, choose whether requests need approval. The Auto-Approve permissions skip approval.

### B) With declarative

Seerr's API key comes from SOPS (`API_KEY` env var). Automatic (`media-seerr-config`, Seerr's documented API, after the Jellyfin, Sonarr and Radarr units):

- Steps 1–2, while Seerr has no admin: signs in with the shared Jellyfin admin.
- Step 3, while no library is enabled.
- Step 4, while Seerr has no Radarr or Sonarr server. Quality profile `declarative.seerr.qualityProfile`.
- Steps 5–6, while empty: the LAN URL when web-gate exposes the service, else `https://<name>.wochap.local`.
- Finishes the wizard when it did the sign-in itself. A wizard you started by hand stays open: check the pages, and select **Finish Setup**.

Manual: step 7.

## Mobile/TV clients

No native app. Open the LAN URL in a mobile browser, and add it to the home screen (PWA). Users sign in with their Jellyfin account.

## Troubleshooting

- Logs: `journalctl -u podman-media-seerr`, `journalctl -u media-seerr-config`.
- Sign-in step fails: Jellyfin was set up with a login other than `admin.username`. Finish steps 1–2 by hand, then `sudo systemctl restart media-seerr-config`.
- Radarr/Sonarr test fails: use the container name, never `127.0.1.1` or `*.wochap.local`.

## Reset / backup

State: `/var/lib/media-server/seerr` (settings, requests, users). Back it up whole.

To reset: `sudo systemctl stop podman-media-seerr`, delete the directory, `sudo systemctl start podman-media-seerr`. With declarative, steps 1–6 come back. Requests and imported users are lost.

## Upgrade

Option `images.seerr`, image `ghcr.io/seerr-team/seerr`. [Release notes](https://github.com/seerr-team/seerr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
