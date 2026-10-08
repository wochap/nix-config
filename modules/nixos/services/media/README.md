# Media stack

Self-hosted media server under `_custom.services.media`: request, download, organize and stream movies, series, ebooks and audiobooks. Each service is a podman container. All containers run as the shared `media` user (2000:2000) on a shared `media` podman network with DNS. An optional declarative layer wires the services together from SOPS secrets.

## Services

| Service | Purpose | Kind | On this host | On the LAN (when exposed) | Between containers |
|---|---|---|---|---|---|
| [Jellyfin](jellyfin/README.md) | Streams movies and series | user | `https://jellyfin.wochap.local` | `https://jellyfin.<domain>` | `media-jellyfin:8096` |
| [Seerr](seerr/README.md) | Users request movies and series | user | `https://seerr.wochap.local` | `https://seerr.<domain>` | `media-seerr:5055` |
| [Calibre-Web Automated](calibre-web/README.md) | Ebook library and reader | user | `https://calibre-web.wochap.local` | `https://calibre-web.<domain>` | `media-calibre-web:8083` |
| [Audiobookshelf](audiobookshelf/README.md) | Audiobook library and player | user | `https://audiobookshelf.wochap.local` | `https://audiobookshelf.<domain>` | `media-audiobookshelf:13378` |
| [Sonarr](sonarr/README.md) | Finds and imports series | admin | `http://127.0.1.1:21101` | no | `media-sonarr:8989` |
| [Radarr](radarr/README.md) | Finds and imports movies | admin | `http://127.0.1.1:21111` | no | `media-radarr:7878` |
| [Prowlarr](prowlarr/README.md) | Manages indexers for the others | admin | `http://127.0.1.1:21121` | no | `media-prowlarr:9696` |
| [qBittorrent](qbittorrent/README.md) | Downloads torrents | admin | `http://127.0.1.1:21131` | no | `media-qbittorrent:8080` (`media-vpn:8080` with VPN) |
| [Bazarr](bazarr/README.md) | Downloads subtitles | admin | `http://127.0.1.1:21141` | no | `media-bazarr:6767` |
| [LazyLibrarian](lazylibrarian/README.md) | Finds ebooks and audiobooks | admin | `http://127.0.1.1:21151` | no | `media-lazylibrarian:5299` |

`<domain>` is `web-gate.domain`, for example `gdesktop.geanmar.com`. User apps also answer on their loopback port (`127.0.1.1:21001`, `21011`, `21021`, `21031`).

### Who can reach which URL

| URL | Example | Reachable from |
|---|---|---|
| Loopback port, `http://127.0.1.1:<port + 1>` | `http://127.0.1.1:21101` | This host only. Always on. |
| Local vhost, `https://<name>.wochap.local` | `https://seerr.wochap.local` | This host only. On when `services.<svc>.proxy` is true (default for user apps). |
| LAN vhost, `https://<name>.<web-gate.domain>` | `https://jellyfin.gdesktop.geanmar.com` | Any device on the LAN, on trusted connections only. On when `_custom.services.web-proxies.<name>.expose.enable` is true. See `../web-proxies/README.md`. |
| Container, `http://media-<name>:<port>` | `http://media-sonarr:8989` | Other containers on the `media` network only. Use this address when you connect one service to another. |

gdesktop exposes Jellyfin, Seerr, Audiobookshelf and Calibre-Web on the LAN. Admin UIs never get a LAN vhost: they have no web-gate in front, so keep them on the host.

## Architecture

```
               users (browser, mobile/TV apps)
                 |                 |
              Seerr ---------> Jellyfin <-------------------------+
     requests |      |                                            | reads
              v      v                                            |
           Radarr  Sonarr <--- indexers --- Prowlarr ---+         |
              |      |                                  |         |
              +--+---+------------ LazyLibrarian <------+         |
                 | grabs               |                          |
                 v                     |                          |
          qBittorrent (optional gluetun VPN sidecar)              |
                 | writes /data/torrents/<category>               |
                 v                                                |
   Radarr/Sonarr hardlink into /data/media/{movies,series} -------+
                                       ^
                          Bazarr adds subtitles next to the files

   LazyLibrarian moves ebooks     --> /data/media/books/ingest --> Calibre-Web Automated
   LazyLibrarian moves audiobooks --> /data/media/audiobooks    --> Audiobookshelf
```

Storage. `dataRoot` is mounted at `/data` in every container with the same layout. Imports are hardlinks, so qBittorrent keeps seeding without a second copy, and no app needs remote path mappings.

| Host | Container | Used by |
|---|---|---|
| `dataRoot/torrents/{movies,series,books,audiobooks}` | `/data/torrents/...` | qBittorrent categories |
| `dataRoot/media/{movies,series}` | `/data/media/...` | Sonarr/Radarr write, Jellyfin and Bazarr read |
| `dataRoot/media/books/ingest` | `/data/media/books/ingest` | LazyLibrarian writes, Calibre-Web Automated consumes |
| `dataRoot/media/books/library` | `/data/media/books/library` | Calibre library |
| `dataRoot/media/audiobooks` | `/data/media/audiobooks` | LazyLibrarian writes, Audiobookshelf watches |
| `stateDir/<svc>` (`/var/lib/media-server/<svc>`) | `/config` | Per-service state |

`media-data-dirs.service` creates the `dataRoot` tree after the disk is mounted.

## NixOS options

All under `_custom.services.media`. Defined in `default.nix`.

| Option | Default | Purpose |
|---|---|---|
| `enable` | `false` | Turns on the stack. |
| `dataRoot` | required | Host directory with `torrents/` and `media/`. Downloads and libraries must be on one filesystem for hardlinks. |
| `stateDir` | `/var/lib/media-server` | One state subdirectory per service. |
| `uid`, `gid` | `2000` | `media` user and group. |
| `bindAddress` | `127.0.1.1` | Host address the loopback ports are published on. |
| `network.{name,interface,subnet,gateway}` | `media`, `podman-media`, `10.90.0.0/24`, `10.90.0.1` | Shared podman network. |
| `images.<svc>` | pinned tag + digest | Container image. See [Upgrading images](#upgrading-images). |
| `services.<svc>.enable` | `false` | Turns on one service. `<svc>` is `jellyfin`, `seerr`, `calibreWeb`, `audiobookshelf`, `sonarr`, `radarr`, `prowlarr`, `qbittorrent`, `bazarr` or `lazylibrarian`. |
| `services.<svc>.port` | per service | Base port. The web UI is published on `port + 1`. |
| `services.<svc>.proxy` | `true` for user apps | Adds the `<name>.wochap.local` vhost. |
| `services.jellyfin.hardwareAcceleration` | `null` | `"vaapi"` or `"nvidia"`. See [Jellyfin](jellyfin/README.md). |
| `services.jellyfin.vaapiDevices` | `[ "/dev/dri/renderD128" ]` | Render nodes for VAAPI. |
| `services.qbittorrent.vpn.*` | off | gluetun sidecar. See [qBittorrent VPN](qbittorrent/README.md#vpn-optional). |
| `declarative.enable` | `false` | Turns on the [declarative layer](#declarative-layer). |
| `declarative.admin.username` | `admin` | Shared admin login. |
| `declarative.admin.passwordSecret.{sopsFile,sopsKey}` | required, `media-admin-password` | Shared admin password. |
| `declarative.apiKeys.<svc>.{sopsFile,sopsKey}` | required, `media-<svc>-api-key` | API keys of `sonarr`, `radarr`, `prowlarr`, `seerr`, `lazylibrarian`. Required only for enabled services. |
| `declarative.seerr.qualityProfile` | `HD-1080p` | Profile Seerr requests with. Falls back to the first profile. |

LAN exposure is set outside this module, with `_custom.services.web-proxies.<name>.expose.enable`.

Example, close to gdesktop (which names its LazyLibrarian key per host):

```nix
_custom.services.media = {
  enable = true;
  dataRoot = "/mnt/storage/media-server";
  services.jellyfin.enable = true;
  services.jellyfin.hardwareAcceleration = "vaapi";
  services.seerr.enable = true;
  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.prowlarr.enable = true;
  services.qbittorrent.enable = true;
  services.bazarr.enable = true;
  services.lazylibrarian.enable = true;
  services.calibreWeb.enable = true;
  services.audiobookshelf.enable = true;
  declarative = {
    enable = true;
    admin.username = "wochap";
    admin.passwordSecret = {
      sopsFile = ../../secrets-sops/local.yaml;
      sopsKey = "local-media-admin-password";
    };
    apiKeys = lib.genAttrs [ "sonarr" "radarr" "prowlarr" "seerr" "lazylibrarian" ] (name: {
      sopsFile = ../../secrets-sops/local.yaml;
      sopsKey = "local-media-${name}-api-key";
    });
  };
};
_custom.services.web-proxies.jellyfin.expose.enable = true;
_custom.services.web-proxies.seerr.expose.enable = true;
```

## Setup order

Each service README has a Setup section with two variants: **A) without declarative** (all manual) and **B) with declarative** (what the bootstrap unit does, and what stays manual). Follow this order. Each step produces an API key or a folder that a later step uses.

0. With declarative: create the [secrets](#secrets), set `declarative`, rebuild, switch.
1. [qBittorrent](qbittorrent/README.md#setup). B: automatic.
2. [Sonarr](sonarr/README.md#setup) and [Radarr](radarr/README.md#setup). B: automatic, except optional profiles and renaming.
3. [Prowlarr](prowlarr/README.md#setup). B: only the indexers.
4. [Jellyfin](jellyfin/README.md#setup). B: only codecs and users.
5. [Seerr](seerr/README.md#setup). B: only users and permissions.
6. [Bazarr](bazarr/README.md#setup). All manual.
7. [LazyLibrarian](lazylibrarian/README.md#setup). Mostly manual. B: copy its API key into SOPS for Prowlarr.
8. [Calibre-Web Automated](calibre-web/README.md#setup). All manual.
9. [Audiobookshelf](audiobookshelf/README.md#setup). All manual.
10. Optional: [qBittorrent VPN](qbittorrent/README.md#vpn-optional).

## Declarative layer

Off by default, so hosts without the secrets still build. Only enabled services get a key or a unit.

**Rule:** automate only through a documented public API, config key or env var. Never write an app's database or config file. Never depend on a password hash format or an endpoint the UI uses internally. Steps without such a route stay manual.

- **API keys** come from SOPS. sops-nix renders them into `/run/secrets/rendered/media-<name>.env`, which sets a documented env var: `SONARR__AUTH__APIKEY`, `RADARR__AUTH__APIKEY`, `PROWLARR__AUTH__APIKEY` ([Servarr docs](https://wiki.servarr.com/sonarr/environment-variables)), Seerr's `API_KEY`. A changed key restarts the container.
- **Admin login**: `admin.username` with the SOPS password, set only on apps that have no login yet.
- **Bootstrap units**: `media-<name>-config.service`, a oneshot that runs after `podman-media-<name>.service` and again whenever the container restarts. It waits up to 5 minutes for the API, adds what is missing, and never removes or edits what exists. Two exceptions: the qBittorrent host in Sonarr/Radarr follows `services.qbittorrent.vpn.enable`, and qBittorrent's auth bypass always includes the `media` subnet.

| Unit | Configures |
|---|---|
| `media-qbittorrent-config` | Auth bypass, login (once), save path, categories |
| `media-sonarr-config`, `media-radarr-config` | Login, root folder, qBittorrent download client |
| `media-prowlarr-config` | Login, Sonarr/Radarr/LazyLibrarian apps with Full Sync |
| `media-jellyfin-config` | Startup wizard and admin, libraries, hardware acceleration |
| `media-seerr-config` | Jellyfin sign-in, libraries, URLs, Radarr and Sonarr |

Manual on purpose:

- Users in Jellyfin, Seerr, Audiobookshelf and Calibre-Web. Seerr permissions and approval rules.
- Indexers, quality profiles, renaming, Jellyfin codecs: personal choices or third-party accounts.
- Bazarr: its settings endpoint is UI-internal, and its API key cannot be preset.
- LazyLibrarian: its API key can be preset only by editing `config.ini`, and `writeCFG` takes undocumented config names.
- Calibre-Web Automated and Audiobookshelf: not covered.

## Secrets

Each secret has a `sopsFile` (which file) and a `sopsKey` (which key, any name). Add only the secrets of enabled services: sops-nix checks at build time that every declared key exists. Quote every value, because YAML reads a key like `1234e5678` as a number.

1. Generate the values:

   ```sh
   openssl rand -base64 24 | tr -d '/+=' | head -c 24; echo   # admin password
   openssl rand -hex 16                                        # Sonarr, Radarr, Prowlarr key
   openssl rand -hex 32                                        # Seerr key
   ```

2. Add them to the SOPS file:

   ```sh
   sops secrets-sops/local.yaml
   ```

   ```yaml
   local-media-admin-password: "q3VhY1bT9xKd0LwZpE7sRf2N"
   local-media-sonarr-api-key: "9c1f0e4b7a2d43f8a6e5b0c1d2e3f405"
   local-media-radarr-api-key: "..."
   local-media-prowlarr-api-key: "..."
   local-media-seerr-api-key: "..."
   local-media-lazylibrarian-api-key: "pending"
   ```

3. Point `declarative.admin.passwordSecret` and `declarative.apiKeys.<svc>` at them (see the [example](#nixos-options)), rebuild, switch.
4. LazyLibrarian generates its own key, so it does not exist before the first start. Keep the placeholder for the first rebuild; `media-prowlarr-config` then only warns. Copy the real key from LazyLibrarian ([step 5](lazylibrarian/README.md#a-without-declarative)), replace the placeholder, rebuild, and run `systemctl restart media-prowlarr-config`.

| Secret | Format | Notes |
|---|---|---|
| Admin password | Letters and digits | Login on qBittorrent, Sonarr, Radarr, Prowlarr, Jellyfin; Seerr signs in to Jellyfin with it. Where an app already has a login, use that same username and password. |
| Sonarr, Radarr, Prowlarr key | 32 lowercase hex | To keep an existing key: `grep -oP '(?<=<ApiKey>)[0-9a-f]{32}' /var/lib/media-server/sonarr/config.xml`. |
| Seerr key | Any string | Replaces the key Seerr generated. |
| LazyLibrarian key | 32 characters | Copy of the key in LazyLibrarian › Config › Interface. Per host. |

A new key replaces the old one at the next container start. Clients outside this stack that used the old key need the new one.

A second host with the stack runs its own instances. Give it its own secrets under keys that do not clash, for example `local-media-glegion-lazylibrarian-api-key`.

## Upgrading images

Images are pinned by tag and digest in `images.<svc>` (`default.nix`). Each service README names its image and caveats.

```sh
IMAGE=ghcr.io/home-operations/sonarr
# recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://$IMAGE | jq -r '.Tags[]' | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://$IMAGE:TAG | sha256sum"
```

1. Read the upstream release notes for breaking changes.
2. Back up the service's state directory (see its README, Reset / backup).
3. Replace both the tag and the `@sha256:` digest, rebuild, switch. The container restarts on the new image and keeps its state.

## Troubleshooting

- Container logs: `journalctl -u podman-media-<name>`.
- Bootstrap logs: `journalctl -u 'media-*-config'`. Run one again: `systemctl restart media-<name>-config`.
- State of everything: `systemctl list-units 'podman-media-*' 'media-*'`.
- A container does not start after the data disk was missing: check `systemctl status media-data-dirs`.
- `nixos-rebuild build` fails in a clone without the git-crypt key (`secrets-git-crypt/nix/default.nix` does not parse). Unrelated to this stack.

## Reset

To start over with empty state (for example, to test the declarative layer). This deletes all app settings, users and watch history. Media files in `dataRoot` stay.

```sh
sudo systemctl stop 'media-*-config.service' 'podman-media-*.service'
sudo podman ps -a --filter name=media- --format '{{.Names}}' | xargs -r sudo podman rm -f
sudo systemctl reset-failed 'podman-media-*'
sudo find /var/lib/media-server -mindepth 1 -delete
sudo rm -rf /var/lib/media-declarative
# start again (or reboot)
systemctl list-unit-files 'podman-media-*' 'media-*-config.service' --no-legend | awk '{print $1}' | xargs sudo systemctl start
```

LazyLibrarian then generates a new API key: update its SOPS value (see [Secrets](#secrets), step 4). To reset one service, see that service's README.

## Notes

- Sonarr, Radarr, Prowlarr, Bazarr and qBittorrent use rootless home-operations images with `--read-only`. Jellyfin, Seerr, Audiobookshelf and gluetun use upstream images. LazyLibrarian and Calibre-Web Automated ship only as s6/PUID images: they start as root with a minimal capability set, then drop privileges.
- The desktop user is in group `media`. Containers run with `UMASK=002`, so library files stay group-writable.
