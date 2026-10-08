# Bazarr

Subtitle manager: watches the Sonarr/Radarr libraries and downloads subtitles next to the files in `/data/media/{movies,series}`. Admin UI, loopback only (`127.0.1.1:21141`). Container `media-bazarr`, port 6767.

State: `/var/lib/media-server/bazarr`.

## Setup

Set up [Sonarr](../sonarr/README.md#setup) and [Radarr](../radarr/README.md#setup) first.

1. Open `http://127.0.1.1:21141` on the host. Go to Settings › General › Security, set Authentication to `Form`, choose a username and password, and save.
2. Go to Settings › Languages:
   - Add your languages to Languages Filter.
   - Under Language Profiles, select **Add New Profile**, and add the languages in order of preference.
   - Under Default Settings, turn on the profile for Series and for Movies.
3. Go to Settings › Providers, and add subtitle providers. Some providers need an account, for example OpenSubtitles.com.
4. Go to Settings › Sonarr. Turn it on, then set Address `media-sonarr`, Port `8989`, and Sonarr's API Key. Select **Test**, then **Save**.
5. Go to Settings › Radarr. Same as Sonarr, with `media-radarr` and port `7878`.

All containers see the same `/data` paths, so Path Mappings stay empty.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/bazarr | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/bazarr:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/bazarr` is kept. Read the upstream release notes first for breaking changes.
