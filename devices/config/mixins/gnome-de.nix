{ config, pkgs, lib, ... }:

{
  config = {
    environment.gnome.excludePackages = with pkgs; [
      baobab
      epiphany
      gnome-tour
      gnome.gnome-contacts
      gnome.gnome-maps
      gnome.gnome-music
      gnome.simple-scan
    ];

    services.xserver.desktopManager.gnome.enable = true;
    services.gnome.games.enable = false;
  };
}
