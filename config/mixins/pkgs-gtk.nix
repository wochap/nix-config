{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # libappindicator-gtk3
        blanket
        dfeet # dbus gui
        gparted
        inkscape # photo editor cli/gui
        pavucontrol
        pinta
        remmina # like vnc

        # APPS
        gnome.cheese # test webcam
        gnome.gnome-calculator
        gnome.gnome-clocks
        gnome.gnome-font-viewer
        gnome.gnome-sound-recorder # test microphone
        gnome.gnome-system-monitor
        gnome.pomodoro
        gnome.zenity # GUI for terminal
      ];
    };
  };
}
