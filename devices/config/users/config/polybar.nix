{ config, pkgs, lib,  ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.gean = {
      services.polybar = lib.mkIf isXorg {
        enable = true;
        script = "polybar mainbar-bspwm &";
        config = ./dotfiles/polybar/config.ini;
      };
    };
  };
}
