# Sonarr

Series manager: searches indexers (via Prowlarr), sends grabs to qBittorrent, imports finished downloads from `/data/torrents` into `/data/media/series` by hardlink. Admin UI, loopback only (`127.0.1.1:21101`), no nginx vhost unless `services.sonarr.proxy = true`. Container `media-sonarr`, port 8989.

Rootless home-operations image, runs read-only as the media user.

State: `/var/lib/media-server/sonarr`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/sonarr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/sonarr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/sonarr` is kept. Read the upstream release notes first for breaking changes.
