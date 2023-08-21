{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  localPkgs = import ../../../config/packages { inherit pkgs lib; };
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # TOOLS
      wmctrl # perform actions on windows
      wmutils-core
      wmutils-opt # required by borders script
      xautomation # simulate key press
      xclip # clipboard cli
      xdo # perform actions on windows
      xdotool # fake keyboard/mouse input
      xlayoutdisplay # fix dpi
      xorg.xdpyinfo # show monitor info
      xorg.xeyes # check if app is running on wayland
      xorg.xkbcomp # print keymap
      xorg.xwininfo # print window info
      xtitle
      localPkgs.neeasade-wmutils-opt

      # APPS CLI
      scrot # screen capture
      autorandr

      # DE
      # alttab # windows like alt + tab
      arandr # xrandr gui
      i3lock-color
      blueberry # bluetooth tray
      caffeine-ng
      feh # wallpaper manager
      kmag # magnifying glass
      nitrogen # wallpaper manager
      pick-colour-picker # color picker gui
      pywal # theme color generator cli

      # APPS
      gpick
      screenkey # show key pressed
    ];
  };
}
