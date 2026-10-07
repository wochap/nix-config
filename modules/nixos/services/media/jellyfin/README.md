# Jellyfin

Media server: plays movies and series from `/data/media/{movies,series}` (read-only). Exposed to users at `https://jellyfin.wochap.local`. Container `media-jellyfin`, port 8096 on the `media` network.

Hardware transcoding: `services.jellyfin.hardwareAcceleration = "vaapi"` passes the render node(s) in `vaapiDevices` (default `/dev/dri/renderD128`) and adds the host `video`/`render` groups. `"nvidia"` uses the CDI device from nvidia-container-toolkit. Pick the backend in Dashboard > Playback > Transcoding after first start.

State: `/var/lib/media-server/jellyfin/{config,cache}`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://docker.io/jellyfin/jellyfin | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://docker.io/jellyfin/jellyfin:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/jellyfin` is kept. Read the upstream release notes first for breaking changes.
