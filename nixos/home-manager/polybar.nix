# Common configuration
{ config, pkgs, ... }:

{
  home.file = {
    ".config/polybar/config".source = ../dotfiles/polybar;
  };

  services.polybar = {
    enable = true;
    script = "polybar top &";
    config = "~/.config/polybar/config";
  };
}
