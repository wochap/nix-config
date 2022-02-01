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

        clipman
        swaylock-effects # lockscreen
        swaybg
        wl-clipboard
        # sway-alttab
      ];
    };
  };
}
