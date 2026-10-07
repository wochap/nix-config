# Calibre-Web Automated

Ebook library and web reader. Anything dropped in `/data/media/books/ingest` (`/cwa-book-ingest` in the container) is converted, added to the Calibre library in `/data/media/books/library`, and removed from ingest. Exposed at `https://calibre-web.wochap.local`. Container `media-calibre-web`, port 8083.

LinuxServer-based (s6-overlay) image: starts as root with the minimal capability set to drop to `PUID`/`PGID`. Default login `admin` / `admin123`, change it on first visit.

State: `/var/lib/media-server/calibre-web`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://docker.io/crocodilestick/calibre-web-automated | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://docker.io/crocodilestick/calibre-web-automated:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/calibre-web` is kept. Read the upstream release notes first for breaking changes.
