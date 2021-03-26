{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      wmctrl # perform actions on windows
      wmutils-core
      xautomation # simulate key press
      xclip # clipboard cli
      xdo # perform actions on windows
      xdotool # fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xev # get key actual name
      xorg.xeyes # check if app is running on wayland
      xorg.xkbcomp # print keymap
    ];
  };
}
