{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # sway-alttab
        # brightnessctl
        mako # notification daemon
        # pactl # control a running PulseAudio sound server
        polkit_gnome
        swaylock
        swaylock # lockscreen
        wl-clipboard
      ];
    };
  };
}
