{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        gnome-menus

        # APPS
        # gnome.bijiben
        # gtimelog
        deluge # torrent client
        evolution # email/calendar client
        gnome.cheese # test webcam
        gnome.dconf-editor
        gnome.eog # image viewer
        gnome.geary # email client
        gnome.gnome-calculator
        gnome.gnome-calendar
        gnome.gnome-clocks
        gnome.gnome-control-center # add google account for gnome apps
        gnome.gnome-font-viewer
        gnome.gnome-sound-recorder # test microphone
        gnome.gnome-system-monitor
        gnome.gucharmap # special char selector
        gnome.nautilus # file manager
        gnome.pomodoro
        gnome.seahorse # manage GnomeKeyring
        prevstable.gnome3.gnome-todo
      ];
    };
  };
}
