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
          MONITOR=DP-0 BAR_HEIGHT=52 polybar --reload mainbar-bspwm &
          MONITOR=DP-2 BAR_HEIGHT=36 polybar --reload mainbar-bspwm &
        '' else ''
          polybar --reload mainbar-bspwm &
        '';
        config = ./dotfiles/polybar/config.ini;
      };
    };
  };
}
