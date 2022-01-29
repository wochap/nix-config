{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # sway-alttab
        # mako # notification daemon
        # pactl # control a running PulseAudio sound server
        swaylock # lockscreen
        wl-clipboard
      ];
    };
  };
}
