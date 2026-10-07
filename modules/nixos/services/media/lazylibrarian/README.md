# LazyLibrarian

Ebook and audiobook acquisition: searches indexers (via Prowlarr), downloads through qBittorrent, then moves finished files into `/data/media/books/ingest` (picked up by Calibre-Web Automated) or `/data/media/audiobooks` (watched by Audiobookshelf). Admin UI, loopback only (`127.0.1.1:21151`). Container `media-lazylibrarian`, port 5299.

Only a LinuxServer.io (s6-overlay) image exists, so this container starts as root with the minimal capability set to drop to `PUID`/`PGID`, instead of `--user`. Ebook format conversion (`ebook-convert`) is not bundled; CWA converts on ingest anyway.

LinuxServer tags are `version-<short sha>`; find the current one with `skopeo inspect docker://lscr.io/linuxserver/lazylibrarian:latest | jq .Labels` and pin that tag plus its digest.

State: `/var/lib/media-server/lazylibrarian`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://lscr.io/linuxserver/lazylibrarian | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://lscr.io/linuxserver/lazylibrarian:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/lazylibrarian` is kept. Read the upstream release notes first for breaking changes.
