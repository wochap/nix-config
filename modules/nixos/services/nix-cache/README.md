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

## Secrets

Every secret lives in a SOPS file that the host options point at (`<option>.sopsFile`), under the key in `<option>.sopsKey`. Generate each value as below, then paste it with `sops <sops-file>`. Write multi-line values as a YAML block scalar (`key: |`, then the lines indented).

Each secret's `sopsFile` and `sopsKey` are up to you. The examples use the default keys.

### Signing key (one per cache server)

Option `server.signingKey`, default key `nix-cache-<hostname>-signing-key`. The name before `-1` labels the key; use the host's `web-gate.domain`.

```sh
nix-store --generate-binary-cache-key cache.gdesktop.example.com-1 secret.key public.key
cat secret.key   # one line, cache.gdesktop.example.com-1:<base64> -> SOPS value
cat public.key   # one line -> other hosts' client.caches.<host>.publicKey
rm secret.key
```

Keep the public key next to the host config, for example `hosts/<host>/nix-cache.pub`, and read it with `lib.fileContents`.

### Cache password (shared)

One user and password for every cache. Two secrets hold it:
- `server.htpasswd` (default key `nix-cache-htpasswd`) holds the hash. nginx reads it.
- `client.netrc` (default key `nix-cache-netrc`) holds the plain password. Nix reads it.

```sh
pass=$(openssl rand -hex 24)
openssl passwd -apr1 "$pass" | sed 's/^/nix:/'   # one line -> htpasswd value
echo "$pass"                                     # -> netrc value, see below
unset pass
```

The netrc value has one line per cache server:

```yaml
nix-cache-netrc: |
  machine cache.gdesktop.example.com login nix password <pass>
  machine cache.glegion.example.com login nix password <pass>
```

### Remote build SSH key (build clients only)

Option `remoteBuilds.sshKey`, default key `nix-remote-build-ssh-key`.

```sh
ssh-keygen -t ed25519 -N "" -C "nix-remote-build" -f build_key
cat build_key       # multi-line -> SOPS value (block scalar)
cat build_key.pub   # -> the builder's remoteBuilds.serve.authorizedKeys
rm build_key
```

Keep the public key next to the client's host config, for example `hosts/<client>/nix-remote-build.pub`.

### Adding a host

1. Generate a signing key for the new host. Store it, and save its `nix-cache.pub`.
2. Add a `machine cache.<new domain> ...` line, with the existing password, to the netrc value. The htpasswd stays the same.
3. On the new host, enable `server` and list the other hosts in `client.caches`. On the other hosts, add the new host to `client.caches`.
4. If the new host builds remotely, reuse the build SSH key, or generate a new one and add its public key to the builder's `authorizedKeys`.
5. Rebuild every host whose config changed.

## Setup

1. Create the secrets above.
2. Rebuild the cache servers, then the clients.
3. On a laptop, list its trusted networks in `web-gate.trustedConnections`. Until you do, its cache is closed to the LAN.

## Check

```sh
# cache answers, with credentials from the netrc
sudo curl --netrc-file /run/secrets/local-nix-cache-netrc https://cache.gdesktop.geanmar.com/nix-cache-info
# substitution from the other host (root, because only root reads the netrc)
sudo nix path-info --store https://cache.gdesktop.geanmar.com "$(readlink -f /run/current-system)"
# remote build (on glegion)
sudo nix store ping --store 'ssh-ng://nix-ssh@gdesktop.geanmar.com?ssh-key=/run/secrets/local-nix-remote-build-ssh-key'
nix build --rebuild nixpkgs#hello -L   # log shows "building ... on ssh-ng://gdesktop.geanmar.com"
```

To build locally only for one run, pass `--builders ""`.
