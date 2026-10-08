# Jellyfin

Media server: plays movies and series from `/data/media/{movies,series}` (read-only). Exposed to users at `https://jellyfin.wochap.local`. Container `media-jellyfin`, port 8096 on the `media` network.

Hardware transcoding: `services.jellyfin.hardwareAcceleration = "vaapi"` passes the render node(s) in `vaapiDevices` (default `/dev/dri/renderD128`) and adds the host `video`/`render` groups. `"nvidia"` uses the CDI device from nvidia-container-toolkit. Pick the backend in Dashboard > Playback > Transcoding after first start.

State: `/var/lib/media-server/jellyfin/{config,cache}`.

## Setup

1. Open `https://jellyfin.wochap.local` on the host. From other LAN devices, use `https://jellyfin.<web-gate.domain>` (for example `https://jellyfin.gdesktop.geanmar.com`) when the proxy is exposed.
2. In the wizard, choose the language and create the admin user.
3. Add the libraries:

   | Content type | Folder |
   |---|---|
   | Movies | `/data/media/movies` |
   | Shows | `/data/media/series` |

4. Finish the wizard, and sign in.
5. Go to Dashboard › Playback › Transcoding:
   - `vaapi`: Hardware acceleration `Video Acceleration API (VAAPI)`, device `/dev/dri/renderD128`.
   - `nvidia`: `Nvidia NVENC`.

   Then turn on the codecs the GPU decodes, and save.
6. Go to Dashboard › Users, and create one user per household member. [Seerr](../seerr/README.md#setup) signs people in with these accounts.

In the mobile and TV apps, the server address is the LAN URL from step 1.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://docker.io/jellyfin/jellyfin | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://docker.io/jellyfin/jellyfin:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/jellyfin` is kept. Read the upstream release notes first for breaking changes.
