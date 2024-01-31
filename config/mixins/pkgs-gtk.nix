{ pkgs, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # libappindicator-gtk3
        blanket # play rain, waves, etc sounds
        dfeet # dbus gui
        gparted # disk partition editor
        inkscape # photo editor cli/gui
        pavucontrol # pulseaudio gui
        pinta # image editor
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
