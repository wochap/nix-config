# Seerr

Request portal (formerly Jellyseerr). Users sign in with their Jellyfin account, request movies/series, admins approve; approved requests go to Radarr/Sonarr. Exposed at `https://seerr.wochap.local`. Container `media-seerr`, port 5055. No media mounts; it only talks to Jellyfin, Sonarr and Radarr over the `media` network.

State: `/var/lib/media-server/seerr`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/seerr-team/seerr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/seerr-team/seerr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/seerr` is kept. Read the upstream release notes first for breaking changes.
