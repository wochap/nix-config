{ config, lib, inputs, ... }:

let
  cfg = config._custom.de.ags;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.ags.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      programs.ags.enable = true;

      xdg.configFile."ags".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles;
    };
  };
}
