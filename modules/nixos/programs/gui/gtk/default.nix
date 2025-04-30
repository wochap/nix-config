{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.gtk;
in {
  options._custom.programs.gtk.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        blanket # play rain, waves, etc sounds
        d-spy # dbus gui
        gparted # disk partition editor
        inkscape # photo editor cli/gui
        pavucontrol # pulseaudio gui
        pwvucontrol # pipewire gui
        pinta # image editor
        remmina # vnc client

        # APPS
        cheese # test webcam
        gnome-calculator
        gnome-clocks
        gnome-font-viewer
        gnome-sound-recorder # test microphone
        gnome-system-monitor
        gnome-pomodoro
        zenity # GUI for terminal
      ];
    };

    # Required by gnome file managers
    programs.file-roller.enable = true;

    programs.gnome-disks.enable = true;
  };
}

