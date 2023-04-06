{ config, pkgs, lib, ... }:

let
  theme = config._theme;

  sway-focus-toggle = pkgs.writeTextFile {
    name = "sway-focus-toggle";
    destination = "/bin/sway-focus-toggle";
    executable = true;

    text = builtins.readFile ./sway-focus-toggle.sh;
  };

  # HACK: fix portals
  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of wayland wm config
  # see: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # SWAYSOCK, /etc/sway/config.d/nixos.conf has it
  dbus-wayland-wm-environment = pkgs.writeTextFile {
    name = "dbus-wayland-wm-environment";
    destination = "/bin/dbus-wayland-wm-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    '';
  };
in { inherit dbus-wayland-wm-environment sway-focus-toggle; }
