{ config, pkgs, lib, ... }:

{
  config = {
    environment.gnome.excludePackages = with pkgs; [
      # gnome.cheese
      # gnome.cheesegnome-photos
      # gnome.gnome-music
      # gnome.gnome-terminal
      gnome.gedit
      epiphany
      evince
      gnome.gnome-characters
      gnome.totem
      gnome.tali
      gnome.iagno
      gnome.hitori
      gnome.atomix
      gnome-tour
    ];

    services.xserver.desktopManager.gnome.enable = true;
  };
}
