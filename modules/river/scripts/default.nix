{ config, pkgs, lib, ... }:

let
  theme = config._theme;

  river-focus-toggle = pkgs.writeTextFile {
    name = "river-focus-toggle";
    destination = "/bin/river-focus-toggle";
    executable = true;

    text = builtins.readFile ./river-focus-toggle.sh;
  };

  # HACK: fix portals
  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of wayland wm config
  # see: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  dbus-wayland-wm-environment = pkgs.writeTextFile {
    name = "dbus-wayland-wm-environment";
    destination = "/bin/dbus-wayland-wm-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment SEATD_SOCK DISPLAY WAYLAND _DISPLAY XDG_CURRENT_DESKTOP=river
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
in { inherit dbus-wayland-wm-environment river-focus-toggle; }
