# Prowlarr

Indexer manager. You configure torrent indexers once here, and Prowlarr syncs them to Sonarr, Radarr and LazyLibrarian. No media mounts.

## URLs

| URL | Reachable from |
|---|---|
| `http://127.0.1.1:21121` | This host |
| `https://prowlarr.wochap.local` | This host, only with `services.prowlarr.proxy = true` |
| `http://media-prowlarr:9696` | Other containers |

No LAN URL: admin UI.

## Depends on / used by

- Depends on: Sonarr (`media-sonarr:8989`), Radarr (`media-radarr:7878`), LazyLibrarian (`media-lazylibrarian:5299`), with their API keys. Indexer sites on the internet.
- Used by: the same three apps, which search through the indexers Prowlarr pushes.

## Setup

Set up [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup) first. LazyLibrarian is optional.

### A) Without declarative

1. Open `http://127.0.1.1:21121` on the host. Choose Authentication Method `Forms (Login Page)`, and create the admin user.
2. Go to Settings › Apps › **+**, and add each app with Sync Level `Full Sync`:

   | App | Prowlarr Server | App Server | API Key |
   |---|---|---|---|
   | Sonarr | `http://media-prowlarr:9696` | `http://media-sonarr:8989` | Sonarr's key |
   | Radarr | `http://media-prowlarr:9696` | `http://media-radarr:7878` | Radarr's key |
   | LazyLibrarian | `http://media-prowlarr:9696` | `http://media-lazylibrarian:5299` | LazyLibrarian's key |

   Select **Test**, then **Save**.
3. Go to Indexers › Add Indexer. Add the indexers you use. Public indexers need no account; private ones ask for credentials or an API key. Select **Test**, then **Save**.
4. Check that the indexers appear in Sonarr › Settings › Indexers. Change indexers in Prowlarr only: Full Sync overwrites edits made in the apps.

### B) With declarative

Prowlarr's API key comes from SOPS (`PROWLARR__AUTH__APIKEY`). Automatic (`media-prowlarr-config`, v1 API):

- Step 1: login, while no user exists.
- Step 2: each enabled app that Prowlarr does not have yet, with the keys from SOPS. An existing app is left as is, even with an old key. LazyLibrarian is added only once its SOPS key is the real one ([Secrets](../README.md#secrets), step 4).

Manual: steps 3–4.

## Troubleshooting

- Logs: `journalctl -u podman-media-prowlarr`, `journalctl -u media-prowlarr-config`.
- An indexer fails the test behind a Cloudflare challenge: it needs FlareSolverr, which this stack does not include.
- `LazyLibrarian app not added` in the journal: turn on LazyLibrarian's API, store its key in SOPS, rebuild, then `sudo systemctl restart media-prowlarr-config`.
- An app has a stale key (for example after a reset): delete it under Settings › Apps, then restart `media-prowlarr-config`.

## Reset / backup

State: `/var/lib/media-server/prowlarr` (database, `config.xml`). Back up `prowlarr.db` and `config.xml`, or use System › Backup.

To reset: `sudo systemctl stop podman-media-prowlarr`, delete the directory, `sudo systemctl start podman-media-prowlarr`. With declarative, the login, apps and API key come back. Indexers are lost.

## Upgrade

Option `images.prowlarr`, image `ghcr.io/home-operations/prowlarr`. [Release notes](https://github.com/Prowlarr/Prowlarr/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
