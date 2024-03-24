{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.xorg-utils;
in {
  options._custom.desktop.xorg-utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        alttab # windows like alt + tab
        arandr # xrandr gui
        autorandr
        feh # wallpaper manager
        gpick
        kmag # magnifying glass
        nitrogen # wallpaper manager
        pick-colour-picker # color picker gui
        screenkey # show key pressed
        scrot # screen capture
        xclip # clipboard cli
      ];
    };
  };
}

