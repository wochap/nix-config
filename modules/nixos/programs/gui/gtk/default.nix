{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.gtk;
in {
  options._custom.programs.gtk.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        blanket # play rain, waves, etc sounds
        d-spy # dbus gui
        inkscape # photo editor cli/gui
        # pinta # image editor
        remmina # vnc client
        file-roller # Required by gnome file managers

        # APPS
        pantheon.elementary-camera # camera app
        gnome-calculator
        gnome-clocks
        gnome-font-viewer
        gnome-sound-recorder # test microphone
        gnome-system-monitor
        gnome-pomodoro
        zenity # GUI for terminal
      ];
    };

    programs.gnome-disks.enable = true;
  };
}

