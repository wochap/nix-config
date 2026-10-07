# Bazarr

Subtitle manager: watches the Sonarr/Radarr libraries and downloads subtitles next to the files in `/data/media/{movies,series}`. Admin UI, loopback only (`127.0.1.1:21141`). Container `media-bazarr`, port 6767.

State: `/var/lib/media-server/bazarr`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/bazarr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/bazarr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/bazarr` is kept. Read the upstream release notes first for breaking changes.
