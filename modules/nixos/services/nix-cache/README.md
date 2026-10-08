# Nix cache

Share Nix stores between hosts on the LAN, and offload builds to a faster host.

- `server`: [harmonia](https://github.com/nix-community/harmonia) serves this host's store, signed on the fly. web-proxies exposes it at `https://cache.<web-gate.domain>` with plain Basic Auth. The DNS name, the certificate and the trusted networks come from web-proxies (see `../web-proxies/README.md`).
- `client.caches`: substitutes from other hosts' caches before the public ones (priority 30, against 40 for cache.nixos.org). It sends the credentials from a netrc file. An unreachable cache costs `connectTimeout` seconds (default 3). Nix then skips it for the rest of the run.
- `remoteBuilds.serve`: accepts builds over SSH as the trusted `nix-ssh` user (`nix.sshServe`, protocol `ssh-ng`).
- `remoteBuilds.machines`: sends builds to those hosts. When the builder is unreachable, the build runs locally after a 3 s SSH timeout.

Current setup:
- gdesktop and glegion each serve a cache and read the other's.
- glegion builds on gdesktop, through the apex record `gdesktop.geanmar.com` (`web-gate.ddns.apex`).
- gdesktop does not build on glegion. The laptop is slower, and two-way builders could pass builds back and forth.

## Why Basic Auth

The cache serves every store path. Store paths can contain secrets, such as values from `secrets-git-crypt` that the config inlines. The gate's cookie login does not work for Nix, so the vhost uses `expose.basicAuthFile`. Nix answers it from `netrc-file`.

## Setup

1. Generate the keys and credentials once, from the repository root. The script needs `sops`, `jq`, `openssl` and `ssh-keygen`, and it can decrypt `secrets-sops/personal.yaml` with the age key.

   ```sh
   modules/nixos/services/nix-cache/keygen.sh
   git add hosts/*/nix-cache.pub hosts/glegion/nix-remote-build.pub
   ```

   - Private parts go into `secrets-sops/personal.yaml`: the per-host signing keys, the htpasswd, the netrc and the remote build SSH key.
   - Public parts go into `hosts/<host>/nix-cache.pub` and `hosts/glegion/nix-remote-build.pub`, which the host configs read.
   - Run the script once only. A second run replaces every key, and you must rebuild both hosts afterwards.

2. Rebuild gdesktop, then glegion.
3. On glegion, list its trusted networks in `web-gate.trustedConnections`. Until you do, its cache is closed to the LAN.

## Check

```sh
# cache answers, with credentials from the netrc
sudo curl --netrc-file /run/secrets/personal-nix-cache-netrc https://cache.gdesktop.geanmar.com/nix-cache-info
# substitution from the other host (root, because only root reads the netrc)
sudo nix path-info --store https://cache.gdesktop.geanmar.com "$(readlink -f /run/current-system)"
# remote build (on glegion)
sudo nix store ping --store 'ssh-ng://nix-ssh@gdesktop.geanmar.com?ssh-key=/run/secrets/personal-nix-remote-build-ssh-key'
nix build --rebuild nixpkgs#hello -L   # log shows "building ... on ssh-ng://gdesktop.geanmar.com"
```

To build locally only for one run, pass `--builders ""`.
