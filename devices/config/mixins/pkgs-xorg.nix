{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
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

      # APPS CLI
      scrot # screen capture

      # DE
      # pywal # theme color generator cli
      # xmagnify # magnifying glass
      # xzoom # magnifying glass
      alttab # windows like alt + tab
      arandr # xrandr gui
      betterlockscreen # screen locker
      blueberry # bluetooth tray
      caffeine-ng
      clipmenu # clipboard manager
      kmag # magnifying glass
      nitrogen # wallpaper manager
      pick-colour-picker # color picker gui
    ];
  };
}
