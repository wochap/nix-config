{ config, pkgs, lib, ... }:

{
  config = {
    _displayServer = "wayland";

    programs.waybar.enable = true;

    environment = {
      etc = {
        "xdg/waybar/config".source = ./dotfiles/config;
        "xdg/waybar/style.css".source = ./dotfiles/style.css;
      };
      systemPackages = with pkgs; [
        waybar # status bar
      ];
    };
  };
}
