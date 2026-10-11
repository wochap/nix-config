# Nix cache

Share Nix stores between hosts on the LAN, and optionally offload builds.

- `server`: [harmonia](https://github.com/nix-community/harmonia) serves the store, signed on the fly, at `https://cache.<web-gate.domain>` behind Basic Auth (DNS, TLS and trusted networks come from web-gate).
- `client.caches`: substitutes from other hosts' caches first (priority 30, vs 40 for cache.nixos.org), with credentials from `netrc-file`. An unreachable cache is skipped after `connectTimeout` (3 s).
- `remoteBuilds.serve`: accepts builds over `ssh-ng` as the trusted `nix-ssh` user.
- `remoteBuilds.machines`: offloads builds to those hosts; falls back to local after a 3 s SSH timeout.

Current setup: gdesktop and glegion each serve a cache and read the other's. Remote builds are not enabled.

Basic Auth, not the gate cookie: Nix can only send netrc credentials, and store paths may contain inlined secrets.

## Secrets

Each option takes a `sopsFile` and `sopsKey`; defaults shown below. Multi-line values go in a YAML block scalar (`key: |`).

**Signing key** (`server.signingKey`, `nix-cache-<hostname>-signing-key`), one per server:

```sh
nix-store --generate-binary-cache-key cache.<domain>-1 secret.key public.key
cat secret.key   # -> SOPS value
cat public.key   # -> hosts/<host>/nix-cache.pub, read by other hosts' client.caches.<host>.publicKey
rm secret.key
```

**Password** (shared by all caches):

```sh
pass=$(openssl rand -hex 24)
openssl passwd -apr1 "$pass" | sed 's/^/nix:/'   # -> server.htpasswd (nix-cache-htpasswd)
echo "$pass"; unset pass                         # -> client.netrc lines below
```

`client.netrc` (`nix-cache-netrc`) must be netrc lines, one per server, not the bare password:

```yaml
nix-cache-netrc: |
  machine cache.gdesktop.geanmar.com login nix password <pass>
  machine cache.glegion.geanmar.com login nix password <pass>
```

**Remote builds** need no secret: the client's nix-daemon uses its host key (`remoteBuilds.sshKeyFile`, default `/etc/ssh/ssh_host_ed25519_key`). Put the client's `.pub` in the builder's `remoteBuilds.serve.authorizedKeys`, and the builder's host `.pub` in the client's `remoteBuilds.machines.<host>.hostKey`.

## Adding a host

1. Generate its signing key and save `hosts/<host>/nix-cache.pub`.
2. Add its `machine` line to the netrc value; the htpasswd stays the same.
3. Enable `server` on it, and cross-list it in every host's `client.caches`.
4. On a laptop, set `web-gate.trustedConnections`, or its cache stays closed to the LAN.
5. Rebuild servers, then clients.

## Check

```sh
# 401 without credentials, cache info with them
sudo curl --netrc-file /run/secrets/local-nix-cache-netrc https://cache.glegion.geanmar.com/nix-cache-info
sudo nix path-info --store https://cache.glegion.geanmar.com "$(readlink -f /run/current-system)"
# remote builds, if enabled (on the client)
sudo nix store ping --store ssh-ng://nix-ssh@gdesktop.geanmar.com
nix build --rebuild nixpkgs#hello -L   # "building ... on ssh-ng://..."; skip with --builders ""
```

`harmonia.service` showing inactive is normal: `harmonia.socket` starts it on demand.
