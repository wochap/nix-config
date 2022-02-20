{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        blanket
        deluge # torrent client
        inkscape # photo editor cli/gui
        networkmanagerapplet

        # APPS
        gnome.cheese # test webcam
        gnome.dconf-editor
        gnome.eog # image viewer
        gnome.gnome-calculator
        gnome.gnome-calendar
        gnome.gnome-clocks
        gnome.gnome-font-viewer
        gnome.gnome-sound-recorder # test microphone
        gnome.gnome-system-monitor
        gnome.gnome-todo
        gnome.nautilus # file manager
        gnome.pomodoro
        # gnome.geary # email client
        # gnome.gnome-control-center # add google account for gnome apps
      ];
    };
  };
}
