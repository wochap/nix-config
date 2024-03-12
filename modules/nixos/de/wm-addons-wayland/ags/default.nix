{ config, lib, inputs, pkgs, ... }:

let
  cfg = config._custom.de.ags;
  inherit (config._custom.globals) configDirectory;
  capslock =
    pkgs.writeScriptBin "capslock" (builtins.readFile ./scripts/capslock.sh);
in {
  options._custom.de.ags.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = [ capslock ];

      programs.ags.enable = true;

      xdg.configFile."ags".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles;
    };
  };
}
