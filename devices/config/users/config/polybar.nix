{ config, pkgs, lib,  ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.gean = {
      services.polybar = lib.mkIf isXorg {
        enable = true;
        script = ''
          if type "xrandr"; then
            for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
              MONITOR=$m polybar --reload mainbar-bspwm &
            done
          else
            polybar --reload mainbar-bspwm &
          fi
        '';
        config = ./dotfiles/polybar/config.ini;
      };
    };
  };
}
