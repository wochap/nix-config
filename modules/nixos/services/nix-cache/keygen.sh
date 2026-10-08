#!/usr/bin/env bash
# Generates the nix-cache secrets once and stores them in a SOPS file.
#
#   modules/nixos/services/nix-cache/keygen.sh [sops-file] [host...]
#
# Defaults: secrets-sops/personal.yaml, hosts gdesktop and glegion,
# domain <host>.geanmar.com. Run it from the repository root.
#
# Writes to the SOPS file (private parts):
#   personal-nix-cache-<host>-signing-key  harmonia signing key, per host
#   personal-nix-cache-htpasswd            Basic Auth for every cache
#   personal-nix-cache-netrc               matching netrc for every client
#   personal-nix-remote-build-ssh-key      root SSH key for remote builds
# Writes to the repository (public parts, read by the host configs):
#   hosts/<host>/nix-cache.pub
#   hosts/glegion/nix-remote-build.pub (REMOTE_BUILD_CLIENT)
set -euo pipefail

sops_file=${1:-secrets-sops/personal.yaml}
shift || true
hosts=("$@")
[ "${#hosts[@]}" -gt 0 ] || hosts=(gdesktop glegion)
zone=${NIX_CACHE_ZONE:-geanmar.com}
client=${REMOTE_BUILD_CLIENT:-glegion}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
chmod 700 "$tmp"

put() {
  # sops set wants a JSON-encoded value.
  jq -Rs . <"$2" >"$tmp/value.json"
  sops set --value-file "$sops_file" "[\"$1\"]" "$tmp/value.json"
}

for host in "${hosts[@]}"; do
  nix-store --generate-binary-cache-key "$host.$zone-1" "$tmp/$host.sec" "hosts/$host/nix-cache.pub"
  put "personal-nix-cache-$host-signing-key" "$tmp/$host.sec"
  echo "signing key: hosts/$host/nix-cache.pub"
done

pass=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32)
printf 'nix:%s\n' "$(openssl passwd -apr1 "$pass")" >"$tmp/htpasswd"
: >"$tmp/netrc"
for host in "${hosts[@]}"; do
  printf 'machine cache.%s.%s login nix password %s\n' "$host" "$zone" "$pass" >>"$tmp/netrc"
done
put personal-nix-cache-htpasswd "$tmp/htpasswd"
put personal-nix-cache-netrc "$tmp/netrc"
echo "cache credentials: user nix, password only in $sops_file"

ssh-keygen -q -t ed25519 -N "" -C "root@$client nix-remote-build" -f "$tmp/build_key"
put personal-nix-remote-build-ssh-key "$tmp/build_key"
cp "$tmp/build_key.pub" "hosts/$client/nix-remote-build.pub"
echo "remote build key: hosts/$client/nix-remote-build.pub"

echo "Next: git add hosts/*/nix-cache.pub hosts/$client/nix-remote-build.pub, then rebuild every host."
