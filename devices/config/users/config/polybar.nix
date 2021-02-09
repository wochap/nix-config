{ config, pkgs, lib,  ... }:

let
  isXorg = config._displayServer == "xorg";
  isDesktop = config.networking.hostName == "gdesktop";
in
{
  config = {
    home-manager.users.gean = {
      services.polybar = lib.mkIf isXorg {
        enable = true;
        package = pkgs.polybar.override {
          alsaSupport = true;
          mpdSupport = true;
          pulseSupport = true;
        };
        # Fixes: https://github.com/nix-community/home-manager/issues/1616
        script = "";
        config = ./dotfiles/polybar/config.ini;
      };
    };
  };
}
