{ config, pkgs, lib, ... }:

{
  config = {
    environment.gnome.excludePackages = with pkgs; [
      baobab
      epiphany
      gnome-tour
      gnome.gnome-contacts
      gnome.gnome-maps
      gnome.simple-scan
      gnome.gnome-shell-extensions
      gnomeExtensions.blur-my-shell
      gnome.gnome-tweaks
    ];

    services.xserver.desktopManager.gnome.enable = true;
    services.gnome.games.enable = false;
  };
}
