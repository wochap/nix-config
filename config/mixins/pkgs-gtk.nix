{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        blanket
        dfeet # dbus gui
        gparted
        inkscape # photo editor cli/gui
        pinta
        remmina # like vnc
        pavucontrol

        # APPS
        gnome.cheese # test webcam
        gnome.gnome-calculator
        gnome.gnome-clocks
        gnome.gnome-sound-recorder # test microphone
        gnome.gnome-system-monitor
        gnome.pomodoro
        gnome.gnome-font-viewer
      ];
    };
  };
}
