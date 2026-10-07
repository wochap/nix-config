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

## Post-deploy checklist

Order matters; each step feeds API keys into the next.

1. **qBittorrent** `127.0.1.1:21131`. First password: `journalctl -u podman-media-qbittorrent | grep password`. Options > Web UI: set a password, tick "Bypass authentication for clients in whitelisted IP subnets" with `10.90.0.0/24` (or create a dedicated user). Options > Downloads: default save path `/data/torrents`, categories `movies`, `series`, `books`, `audiobooks` with save paths `/data/torrents/<category>`.
2. **Prowlarr** `127.0.1.1:21121`. Create admin. Add indexers. Settings > General: copy API key.
3. **Sonarr** `127.0.1.1:21101`. Root folder `/data/media/series`. Download client: qBittorrent, host `media-qbittorrent` (or `media-vpn` with VPN), port 8080, category `series`. Media Management: enable "Use Hardlinks instead of Copy". Settings > General: copy API key.
4. **Radarr** `127.0.1.1:21111`. Same as Sonarr with `/data/media/movies` and category `movies`.
5. **Prowlarr > Settings > Apps**: add Sonarr (`http://media-sonarr:8989`), Radarr (`http://media-radarr:7878`), LazyLibrarian (`http://media-lazylibrarian:5299`), each with its API key and Prowlarr server `http://media-prowlarr:9696`. Sync indexers.
6. **Bazarr** `127.0.1.1:21141`. Settings > Sonarr: `media-sonarr`, 8989, API key. Settings > Radarr: `media-radarr`, 7878, API key. Add subtitle providers and languages.
7. **Jellyfin** `https://jellyfin.wochap.local`. Wizard, create admin. Libraries: Movies at `/data/media/movies`, Shows at `/data/media/series`. Dashboard > Playback > Transcoding: VA-API, device `/dev/dri/renderD128`. Create one Jellyfin user per household member.
8. **Seerr** `https://seerr.wochap.local`. Choose Jellyfin, server `http://media-jellyfin:8096`, sign in as the Jellyfin admin, sync libraries. Add Radarr (`media-radarr`, 7878, API key, root `/data/media/movies`, quality profile, mark default) and Sonarr (`media-sonarr`, 8989, root `/data/media/series`). Users > enable auto-approve or leave requests for admin approval.
9. **Calibre-Web Automated** `https://calibre-web.wochap.local`. Login `admin`/`admin123`, change password. Library location `/calibre-library` (created empty on first start). Ingest folder is `/cwa-book-ingest`.
10. **Audiobookshelf** `https://audiobookshelf.wochap.local`. Create root user. Library type Audiobooks, folder `/data/media/audiobooks`. Settings: enable folder watcher.
11. **LazyLibrarian** `127.0.1.1:21151`. Config > Downloaders: qBittorrent host `media-qbittorrent` (or `media-vpn`), port 8080, label `books`/`audiobooks`. Config > Importing: eBook destination folder `/data/media/books/ingest`, AudioBook destination folder `/data/media/audiobooks`, download dir `/data/torrents/books`. Config > Providers: indexers come from Prowlarr sync (step 5) or add Torznab feeds pointing at `http://media-prowlarr:9696/<id>/api` with the Prowlarr API key.
12. **VPN (later)**: add `local-media-vpn-env` to `secrets-sops/local.yaml` with the provider secrets, set `services.qbittorrent.vpn.environment` and `vpn.enable = true`, rebuild, then switch the qBittorrent host in Sonarr, Radarr and LazyLibrarian from `media-qbittorrent` to `media-vpn`. Check `journalctl -u podman-media-vpn` for the tunnel IP.

## Notes

- Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent use rootless home-operations images with `--read-only`. Jellyfin, Seerr, Audiobookshelf, gluetun are upstream images. LazyLibrarian and Calibre-Web Automated only ship as s6/PUID images; they start as root with the minimal capability set to drop privileges.
- The desktop user is added to group `media`; containers run with `UMASK=002` so library files stay group-writable.
- `nixos-rebuild build` cannot run in a clone without the git-crypt key (`secrets-git-crypt/nix/default.nix` fails to parse). This is unrelated to the stack.
