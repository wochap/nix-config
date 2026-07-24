{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cu = "${pkgs.coreutils}/bin";
  cfg = config.home.copyFiles;

  copyFileOpts = { name, config, ... }: {
    options = {
      source = mkOption {
        type = types.path;
        description = "Source file to copy.";
      };
      executable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to make the copied file executable.";
      };
    };
  };

  toCopyCmd = destination: opts: ''
    if [ ! -e "$HOME/${destination}" ]; then
      $DRY_RUN_CMD ${cu}/mkdir -p $(${cu}/dirname "$HOME/${destination}")
      $DRY_RUN_CMD ${cu}/cp $VERBOSE_ARG ${toString opts.source} "$HOME/${destination}"
      ${optionalString opts.executable ''
        $DRY_RUN_CMD ${cu}/chmod +x "$HOME/${destination}"
      ''}
    fi
  '';
in
{
  options = {
    home.copyFiles = mkOption {
      type = types.attrsOf (types.submodule copyFileOpts);
      description = "Files to copy into the home directory, only if the destination does not already exist.";
      default = { };
    };
  };

  config = {
    home.activation.copyFiles = hm.dag.entryAfter [ "writeBoundary" ] (
      concatStringsSep "\n" (mapAttrsToList toCopyCmd cfg)
    );
  };
}
