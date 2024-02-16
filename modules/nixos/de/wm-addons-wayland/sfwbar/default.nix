{ config, lib, pkgs, ... }:

let
  cfg = config._custom.de.sfwbar;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.sfwbar.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ sfwbar ];

      xdg.configFile."sfwbar/sfwbar.config".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/sfwbar.config;
    };
  };
}

