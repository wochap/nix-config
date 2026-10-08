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

With `declarative.enable` (see [Declarative configuration](#declarative-configuration)), a rebuild wires the services together and sets one shared admin login. What stays manual is either a personal choice or has no stable, documented route. Without it, follow every step in the service READMEs.

Admin UIs (`127.0.1.1:<port>`) open only on the host. User-facing apps also open on the LAN at `https://<name>.<web-gate.domain>` when their proxy is exposed (see `../web-proxies/README.md`). Between containers, always use the container name, for example `media-sonarr:8989`.

1. Turn on LazyLibrarian's API and copy its key (see [LazyLibrarian](lazylibrarian/README.md#setup)), add the secrets to SOPS ([Secrets](#secrets)), turn on `declarative`, rebuild, switch.
2. [qBittorrent](qbittorrent/README.md#setup): automatic (login, auth bypass, save path, categories).
3. [Sonarr](sonarr/README.md#setup) and [Radarr](radarr/README.md#setup): automatic (login, root folder, download client). Optional: profiles, renaming.
4. [Prowlarr](prowlarr/README.md#setup): indexers. Automatic: login, Sonarr, Radarr and LazyLibrarian apps.
5. [Jellyfin](jellyfin/README.md#setup): codecs and users. Automatic on a new server: wizard and admin, libraries, hardware acceleration.
6. [Seerr](seerr/README.md#setup): users and permissions. Automatic: Jellyfin sign-in, libraries, URLs, Radarr and Sonarr.
7. [Bazarr](bazarr/README.md#setup): all manual (login, languages, providers, Sonarr and Radarr).
8. [Calibre-Web Automated](calibre-web/README.md#setup): all manual.
9. [Audiobookshelf](audiobookshelf/README.md#setup): all manual.
10. [LazyLibrarian](lazylibrarian/README.md#setup): login, downloader, folders. Automatic: Prowlarr pushes indexers.
11. Optional, later: [qBittorrent VPN](qbittorrent/README.md#vpn-optional). With `declarative` on, the next rebuild moves the qBittorrent host in Sonarr and Radarr between `media-qbittorrent` and `media-vpn`; in LazyLibrarian, and without `declarative`, change it by hand. To see the tunnel IP, run `journalctl -u podman-media-vpn`.

## Declarative configuration

```nix
_custom.services.media.declarative = {
  enable = true;
  sopsFile = ../../secrets-sops/local.yaml;
  # Optional; the defaults are media-<service>-api-key and media-admin-password.
  apiKeys.sonarr.sopsKey = "local-media-sonarr-api-key";
  apiKeys.radarr.sopsKey = "local-media-radarr-api-key";
  apiKeys.prowlarr.sopsKey = "local-media-prowlarr-api-key";
  apiKeys.seerr.sopsKey = "local-media-seerr-api-key";
  apiKeys.lazylibrarian.sopsKey = "local-media-lazylibrarian-api-key";
  admin.username = "admin";
  admin.passwordSecret.sopsKey = "local-media-admin-password";
  # Quality profile for Seerr's Radarr/Sonarr servers (default HD-1080p).
  seerr.qualityProfile = "HD-1080p";
};
```

Off by default, so hosts without the secrets still build. Only enabled services get a key or a unit.

**Rule:** the layer automates only what goes through a documented public API or a documented config key or env var. It never writes an app's database or config file, and never depends on a password hash format or an endpoint the app's UI uses internally. Steps without such a route stay manual.

- **API keys** reach the containers through documented env vars, from env files that sops-nix renders (`/run/secrets/rendered/media-<name>.env`): `SONARR__AUTH__APIKEY`, `RADARR__AUTH__APIKEY`, `PROWLARR__AUTH__APIKEY` ([Servarr environment variables](https://wiki.servarr.com/sonarr/environment-variables)) and Seerr's `API_KEY` (Seerr docs, Settings › General).
- **Admin login**: `admin.username` and the SOPS password, set only on apps that have no login yet.
- **Bootstrap units**: `media-<name>-config.service`, a oneshot after `podman-media-<name>.service`, rerun whenever the container restarts. Each one waits for the API (up to 5 minutes), adds only what is missing, and never removes or edits what is there. Exceptions: the qBittorrent host in Sonarr/Radarr follows `services.qbittorrent.vpn.enable` when it is one of `media-qbittorrent`/`media-vpn`, and qBittorrent's whitelist always contains the `media` subnet.

Logs: `journalctl -u 'media-*-config'`. To run a unit again: `systemctl restart media-<name>-config`.

| Unit | Does | Route |
|---|---|---|
| `media-qbittorrent-config` | Auth bypass for the `media` subnet. Login, once. Default save path `/data/torrents` with Automatic Torrent Management while it is still `/config/Downloads`. Categories `movies`, `series`, `books`, `audiobooks` at `/data/torrents/<category>`. | WebUI API: `auth/login`, `app/preferences`, `app/setPreferences`, `torrents/categories`, `torrents/createCategory` |
| `media-sonarr-config`, `media-radarr-config` | Login while none. Root folder. qBittorrent download client (category `series`/`movies`). Warns when hardlinks are off. | v3 API: `config/host`, `rootfolder`, `downloadclient`, `downloadclient/schema`, `config/mediamanagement` |
| `media-prowlarr-config` | Login while none. Apps Sonarr, Radarr, LazyLibrarian with Full Sync. | v1 API: `config/host`, `applications`, `applications/schema` |
| `media-jellyfin-config` | Startup wizard with the admin, while not completed. As that admin: Movies and Shows libraries, hardware acceleration while `none`. | OpenAPI: `Startup/User`, `Startup/Complete`, `Users/AuthenticateByName`, `Library/VirtualFolders`, `System/Configuration/encoding` |
| `media-seerr-config` | Jellyfin sign-in while no admin. Library sync, Movies and Shows enabled while none is. Jellyfin External URL and Application URL while empty. Radarr and Sonarr while none. Finishes the wizard when it did the sign-in. | OpenAPI: `auth/jellyfin`, `settings/jellyfin/library/sync`, `settings/jellyfin/library/{id}`, `settings/jellyfin`, `settings/main`, `settings/radarr`, `settings/sonarr`, `settings/initialize` |

qBittorrent's API cannot say whether a password exists. The unit sets the login once, when the shared login does not work yet, and then writes `/var/lib/media-declarative/qbittorrent-login`; a password changed later in the UI is kept. A password set by hand *before* the first run is replaced, so either enable the layer first, or put that password in SOPS.

Manual on purpose:

- **Individual users** in Jellyfin, Seerr, Audiobookshelf, Calibre-Web; Seerr permissions and approval rules.
- **Indexers, quality profiles, renaming, Jellyfin codecs**: personal choices or third-party accounts.
- **Bazarr** (login, languages, subtitle providers, Sonarr and Radarr): its settings endpoint is hidden from Bazarr's API documentation (UI-internal), and the API key cannot be preset.
- **LazyLibrarian** (login, API key, downloader, folders): the API key cannot be preset except by editing `config.ini`, and `writeCFG` takes config names that are not documented.
- **Calibre-Web Automated, Audiobookshelf**: not covered.
- **Jellyfin or Seerr set up by hand with another admin login**: the units skip the steps that need the admin. Seerr's other steps still run, with the API key.

### Secrets

Each secret has two options: `sopsFile` (which SOPS file) and `sopsKey` (which key in it, any name you like). The headings below name the options and their default keys. Add only the secrets of enabled services; sops-nix checks at build time that every declared key exists.

Open the SOPS file you chose, and add one line per secret:

```sh
sops path/to/secrets.yaml
```

```yaml
media-admin-password: "..."
media-sonarr-api-key: "9c1f0e4b7a2d43f8a6e5b0c1d2e3f405"
```

Host config, for example with every secret in one file and the default keys:

```nix
_custom.services.media.declarative = {
  enable = true;
  admin.passwordSecret.sopsFile = ../../secrets/media.yaml;
  apiKeys = lib.genAttrs [ "sonarr" "radarr" "prowlarr" "seerr" "lazylibrarian" ] (_: {
    sopsFile = ../../secrets/media.yaml;
  });
};
```

Quote every value: YAML reads a key like `1234e5678...` as a number.

#### Admin password: `admin.passwordSecret` (default key `media-admin-password`)

The password of `admin.username` in qBittorrent, Sonarr, Radarr, Prowlarr and Jellyfin; Seerr signs in with it. Generate one:

```sh
openssl rand -base64 24 | tr -d '/+=' | head -c 24; echo
```

It looks like `q3VhY1bT9xKd0LwZpE7sRf2N`. Letters and digits only, so no app rejects or mangles it. Where an app already has a login (for example a Jellyfin set up by hand), the layer keeps that login; use the same username and password here so Jellyfin and Seerr steps can sign in.

#### Sonarr, Radarr, Prowlarr API keys: `apiKeys.<service>` (default key `media-<service>-api-key`)

32 lowercase hex characters, like `9c1f0e4b7a2d43f8a6e5b0c1d2e3f405`. Where the app already runs, reuse its key so connections made by hand keep working:

```sh
grep -oP '(?<=<ApiKey>)[0-9a-f]{32}' /var/lib/media-server/sonarr/config.xml   # or radarr, prowlarr
```

Otherwise generate one:

```sh
openssl rand -hex 16
```

A new key replaces the old one at the next start of the container; anything outside this stack that used the old key needs the new one.

#### Seerr API key: `apiKeys.seerr` (default key `media-seerr-api-key`)

Any random string; Seerr uses `API_KEY` as given. Generate one with `openssl rand -hex 32`. It replaces the key Seerr generated; anything outside this stack that used that key needs the new one (Seerr › Settings › General shows it).

#### LazyLibrarian API key: `apiKeys.lazylibrarian` (default key `media-lazylibrarian-api-key`)

A copy of the key LazyLibrarian generated, 32 characters. In LazyLibrarian, go to Config › Interface, turn on the API, generate a key, save, and paste that key here. Prowlarr pushes indexers with it.

#### New host

A host without the media stack needs nothing. A second host that runs the stack has its own instances, so it needs its own secrets: a new admin password (or the same one) and new API keys. Store them under keys that do not clash with the first host's, set `declarative.enable`, `admin.*` and every `apiKeys.<service>` in that host's file, then rebuild that host.

## Notes

- Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent use rootless home-operations images with `--read-only`. Jellyfin, Seerr, Audiobookshelf, gluetun are upstream images. LazyLibrarian and Calibre-Web Automated only ship as s6/PUID images; they start as root with the minimal capability set to drop privileges.
- The desktop user is added to group `media`; containers run with `UMASK=002` so library files stay group-writable.
- `nixos-rebuild build` cannot run in a clone without the git-crypt key (`secrets-git-crypt/nix/default.nix` fails to parse). This is unrelated to the stack.
