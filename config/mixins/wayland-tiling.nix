{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        blueberry # bluetooth tray
        caffeine-ng
        libappindicator-gtk3

        clipman
        mako # notification daemon
        swaylock-effects # lockscreen
        swaybg
        wl-clipboard
        # sway-alttab
      ];
    };
  };
}
