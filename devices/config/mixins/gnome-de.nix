{ config, pkgs, lib, ... }:

{
  config = {
    environment.gnome.excludePackages = with pkgs; [
      baobab
      epiphany
      gnome.gnome-contacts
      gnome.gnome-maps
      gnome.gnome-music
      gnome.gnome-tour
      gnome.simple-scan
    ];

    services.xserver.desktopManager.gnome.enable = true;
    services.gnome.games.enable = false;
  };
}
