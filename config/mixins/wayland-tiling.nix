{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
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
