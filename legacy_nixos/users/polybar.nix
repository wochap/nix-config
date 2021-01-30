# Common configuration
{ config, pkgs, ... }:

{
  services.polybar = {
    enable = true;
    script = "polybar mainbar-bspwm &";
    config = ../dotfiles/polybar-example.ini;
    # config = ../dotfiles/polybar.ini;
  };
}
