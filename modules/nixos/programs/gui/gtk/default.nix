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

    # Required by gnome file managers
    programs.file-roller.enable = true;

    programs.gnome-disks.enable = true;
  };
}

