{ config, pkgs, ... }:

{
  config = {
    home-manager.users.gean = {
      services.polybar = {
        enable = true;
        script = "polybar mainbar-bspwm &";
        config = ./dotfiles/polybar/example.ini;
      };
    };
  };
}
