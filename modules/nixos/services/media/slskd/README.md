# slskd

Soulseek client with a web UI and an API. Soulseek is a peer-to-peer network where users share their music folders; it has far more music than public torrent trackers. [Soularr](../soularr/README.md) drives slskd for Lidarr; the UI also works for manual searches. Downloads go to `/data/soulseek/downloads` (partial files in `/data/soulseek/incomplete`). Runs as the media user. Not read-only, because the .NET binary unpacks itself at start.

slskd shares `/data/media/music` read-only. Many peers refuse users who share nothing, so keep it.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21181` | This host |
| `https://slskd.wochap.local` | This host, only with `services.slskd.proxy = true` |
| `http://media-slskd:5030` | Other containers. With `vpn`: `http://media-vpn:5030`. |

No LAN URL: admin UI.

The Soulseek peer port (`listenPort`, default 50300) is published on all host addresses without the VPN. Other peers need it to connect in; forward it on the router for best results. Podman's published ports skip the NixOS firewall.

## Depends on / used by

- Depends on: a Soulseek account (free; slskd creates it on first login if the name is free). Optional: the qBittorrent gluetun sidecar.
- Used by: Soularr. Lidarr imports from its download folder.

## Setup

### A) Without declarative

1. Open `http://127.0.1.1:21181` on the host. The login is `slskd` / `slskd`. Change it: without declarative the web login is the image default.
2. Set the Soulseek account. Either set `services.slskd.credentials` (see B), or enable remote configuration and enter `soulseek.username` and `soulseek.password` in System › Options.
3. Check System › Shares: `/data/media/music` is scanned.

Soularr needs declarative (for the API key), so it does not work in this mode.

### B) With declarative

Automatic, from SOPS through slskd's env vars:

- `SLSKD_API_KEY`: `declarative.apiKeys.slskd`. Soularr uses it. 16 to 255 characters: `openssl rand -hex 32`.
- Web login `SLSKD_USERNAME`/`SLSKD_PASSWORD`: `admin.username` and the shared admin password.
- Soulseek account: `services.slskd.credentials.{sopsFile,sopsKey}`, a key whose value is an env file:

  ```
  SLSKD_SLSK_USERNAME=myname
  SLSKD_SLSK_PASSWORD=...
  ```

Manual: nothing.

## VPN (optional)

Soulseek shows your IP address to other peers. `services.slskd.vpn = true` runs slskd in the qBittorrent gluetun sidecar (`--network=container:media-vpn`), so it needs `services.qbittorrent.vpn.enable`. gluetun then publishes the slskd web UI, and Soularr reaches slskd at `media-vpn:5030`. slskd is `BindsTo` gluetun and restarts with it.

Through the VPN, peers cannot connect in unless the provider forwards a port. slskd can read that port from gluetun's control server (`SLSKD_VPN_*` options); this module does not set that up. Searches and most downloads still work without it.

## Troubleshooting

- Logs: `journalctl -u podman-media-slskd`.
- "Logged in" never appears: wrong Soulseek password, or the name belongs to someone else. Check the credentials env file.
- Few results or slow downloads: open the peer port (see URLs), and keep sharing.

## Reset / backup

State: `/var/lib/media-server/slskd` (`slskd.yml` if any, databases, logs). Downloads stay in `dataRoot`.

To reset: `sudo systemctl stop podman-media-slskd`, delete the directory, `sudo systemctl start podman-media-slskd`. With declarative, the API key, login and account come back. Transfer history is lost.

## Upgrade

Option `images.slskd`, image `docker.io/slskd/slskd`. [Release notes](https://github.com/slskd/slskd/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
