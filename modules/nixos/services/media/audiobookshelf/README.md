# Audiobookshelf

Audiobook (and podcast) library and player with mobile apps. Serves `/data/media/audiobooks` read-only; the folder watcher picks up what LazyLibrarian drops. Exposed at `https://audiobookshelf.wochap.local`. Container `media-audiobookshelf`, listens on 13378 (the image default of 80 cannot be bound by the media user).

State: `/var/lib/media-server/audiobookshelf/{config,metadata}`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/advplyr/audiobookshelf | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/advplyr/audiobookshelf:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/audiobookshelf` is kept. Read the upstream release notes first for breaking changes.
