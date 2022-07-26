{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
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
      wlr.enable = true;
      extraPortals = with pkgs;
        [
          # xdg-desktop-portal-wlr # this causes a delay of 30 seconds on gtk apps
          xdg-desktop-portal-gtk
        ];
      gtkUsePortal = true;
    };
  };
}
