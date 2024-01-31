{ config, lib, pkgs, ... }:

with lib;
let
  cu = "${pkgs.coreutils}/bin";
  cfg = config.home.symlinks;

  toSymlinkCmd = destination: target: ''
    $DRY_RUN_CMD ${cu}/mkdir -p $(${cu}/dirname ${destination})
    $DRY_RUN_CMD ${cu}/ln -sf $VERBOSE_ARG \
      ${target} ${destination}
  '';
in {
  options = {
    home.symlinks = mkOption {
      type = types.attrsOf (types.str);
      description = "A list of symlinks to create.";
      default = { };
    };
  };

  # TODO Convert to config.lib.file.mkOutOfStoreSymlink ./path/to/file/to/link;
  # https://github.com/nix-community/home-manager/issues/257#issuecomment-831300021
  config = {
    home.activation.symlinks = hm.dag.entryAfter [ "writeBoundary" ]
      (concatStringsSep "\n" (mapAttrsToList toSymlinkCmd cfg));
  };
}

