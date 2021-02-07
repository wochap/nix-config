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
        # TODO: try https://github.com/polybar/polybar/issues/763
        script = if isDesktop then ''
          MONITOR=DP-0 polybar main &
          MONITOR=DP-2 polybar main &
        '' else ''
          polybar main &
        '';
        config = ./dotfiles/polybar/config.ini;
      };
    };
  };
}
