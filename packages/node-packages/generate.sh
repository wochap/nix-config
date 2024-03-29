#!/usr/bin/env bash
set -eu -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${DIR}
rm -f ./node-env.nix
node2nix -i node-packages.json -o node-packages.nix -c composition.nix --supplement-input node-packages-supplement.json
# using --no-out-link in nix-build argument would cause the
# gc to run before the script finishes
# which would cause a failure
# it's safer to just remove the link after the script finishes
# see https://github.com/NixOS/nixpkgs/issues/112846 for more details
rm ./result
