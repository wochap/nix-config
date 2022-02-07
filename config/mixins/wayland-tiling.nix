{ config, pkgs, lib, ... }:

{
  config = {
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

        clipman
        wdisplays
        swaylock-effects # lockscreen
        swaybg
        wl-clipboard
        # sway-alttab
      ];
      variables = { _JAVA_AWT_WM_NONREPARENTING = "1"; };
    };

    # slack on wayland to share screen
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      gtkUsePortal = true;
    };
  };
}
