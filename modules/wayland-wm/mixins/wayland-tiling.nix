{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;

  # HACK: fix portals
  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of wayland wm config
  # see: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # SWAYSOCK, /etc/sway/config.d/nixos.conf has it
  restart-pipewire-and-portal-services = pkgs.writeTextFile {
    name = "restart-pipewire-and-portal-services";
    destination = "/bin/restart-pipewire-and-portal-services";
    executable = true;

    text = ''
      dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
      systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        restart-pipewire-and-portal-services

        blueberry # bluetooth tray
        caffeine-ng
        libappindicator-gtk3

        # utilities for pick color, screenshot
        swappy
        slurp
        grim
        gnome.zenity
        wlr-randr
        wf-recorder

        cliphist
        clipman
        fuzzel
        swaybg
        swaylock-effects # lockscreen
        wdisplays
        wl-clipboard
        # sway-alttab
      ];

      sessionVariables = {

        # enable wayland support (electron apps)
        NIXOS_OZONE_WL = "1";

        XDG_SESSION_TYPE = "wayland";

        # enable portal
        GTK_USE_PORTAL = "1";
      };
    };

    # slack on wayland to share screen
    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        inputs.xdg-portal-hyprland.packages.${pkgs.system}.default
        xdg-desktop-portal-gtk
      ];
    };
  };
}
