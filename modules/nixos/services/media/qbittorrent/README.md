# qBittorrent

Download client. Writes to `/data/torrents/<category>`; the *arr apps hardlink from there, so keep seeding without duplicating files. Admin UI, loopback only (`127.0.1.1:21131`). Container `media-qbittorrent`, web UI port 8080.

## VPN (optional)

`services.qbittorrent.vpn.enable = true` starts a gluetun sidecar (`media-vpn`, image `docker.io/qmcgaw/gluetun`). qBittorrent then runs with `--network=container:media-vpn`: it has no interface of its own, so all its traffic goes through the tunnel and gluetun's firewall. Other containers reach the web UI at `media-vpn:8080`; the loopback port is published by gluetun. qBittorrent is `BindsTo` gluetun and restarts with it.

Configuration is split:

- `vpn.environment`: non-secret gluetun variables (`VPN_SERVICE_PROVIDER`, `VPN_TYPE`, `SERVER_COUNTRIES`, ...).
- `vpn.sopsKey` (default `local-media-vpn-env`): key in `secrets-sops/local.yaml` whose value is an env file with the secrets, for example:

  ```
  WIREGUARD_PRIVATE_KEY=...
  WIREGUARD_ADDRESSES=10.x.y.z/32
  ```

  Add the key before enabling; sops-nix checks it at build time.
- `vpn.environmentFiles`, `vpn.extraOptions`: escape hatches.

To swap gluetun for another VPN container, change `images.gluetun` and adjust `vpn.environment`; the namespace sharing does not depend on gluetun specifics.

State: `/var/lib/media-server/qbittorrent`.

## Upgrade

Images are pinned by tag and digest in `_custom.services.media.images` (`../default.nix`). To move to a new version:

```sh
# list recent tags
nix shell nixpkgs#skopeo nixpkgs#jq -c skopeo list-tags docker://ghcr.io/home-operations/qbittorrent | jq -r ".Tags[]" | sort -V | tail
# digest of the chosen tag
nix shell nixpkgs#skopeo -c sh -c "skopeo inspect --raw docker://ghcr.io/home-operations/qbittorrent:TAG | sha256sum"
```

Replace both the tag and the `@sha256:` digest in the option default, rebuild, switch. The container restarts on the new image; state in `/var/lib/media-server/qbittorrent` is kept. Read the upstream release notes first for breaking changes.
