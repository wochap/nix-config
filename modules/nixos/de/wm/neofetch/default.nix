{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.neofetch;
  inherit (config._custom.globals) configDirectory;
  inherit (lib._custom) relativeSymlink;
in {
  options._custom.wm.neofetch.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch

      # Image preview on terminal
      w3m
      imagemagick
    ];

    _custom.hm = {
      xdg.configFile = {
        "neofetch/config.conf".source =
          relativeSymlink configDirectory ./dotfiles/config.conf;
      };
    };
  };
}
