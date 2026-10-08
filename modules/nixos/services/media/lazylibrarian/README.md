# LazyLibrarian

Ebook and audiobook acquisition: searches indexers (via Prowlarr), downloads through qBittorrent, then moves finished files into `/data/media/books/ingest` (picked up by Calibre-Web Automated) or `/data/media/audiobooks` (watched by Audiobookshelf). Admin UI, loopback only (`127.0.1.1:21151`). Container `media-lazylibrarian`, port 5299.

Only a LinuxServer.io (s6-overlay) image exists, so this container starts as root with the minimal capability set to drop to `PUID`/`PGID`, instead of `--user`. Ebook format conversion (`ebook-convert`) is not bundled; CWA converts on ingest anyway.

LinuxServer tags are `version-<short sha>`; find the current one with `skopeo inspect docker://lscr.io/linuxserver/lazylibrarian:latest | jq .Labels` and pin that tag plus its digest.

State: `/var/lib/media-server/lazylibrarian`.

## Setup

Set up [qBittorrent](../qbittorrent/README.md#setup) and [Prowlarr](../prowlarr/README.md#setup) first.

1. Open `http://127.0.1.1:21151` on the host.
2. Go to Config › Interface, and set a username and password.
3. Go to Config › Downloaders, and turn on qBittorrent:
   - Host: `media-qbittorrent` (`media-vpn` with the VPN enabled), Port `8080`.
   - Label: `books` for ebooks, `audiobooks` for audiobooks.
4. Go to Config › Importing:
   - eBook destination folder: `/data/media/books/ingest`. [Calibre-Web Automated](../calibre-web/README.md#setup) imports from there.
   - AudioBook destination folder: `/data/media/audiobooks`. [Audiobookshelf](../audiobookshelf/README.md#setup) watches it.
   - Download directory: `/data/torrents/books`.
5. Go to Config › Interface, and copy the API key. Add LazyLibrarian as an app in Prowlarr (Prowlarr setup, step 4), and Prowlarr pushes its indexers here. Alternative: under Config › Providers, add Torznab feeds at `http://media-prowlarr:9696/<id>/api` with Prowlarr's API key.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://lscr.io/linuxserver/lazylibrarian | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://lscr.io/linuxserver/lazylibrarian:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/lazylibrarian` is kept. Read the upstream release notes first for breaking changes.
