{ config, pkgs, lib, inputs, ... }:

let
  isHidpi = true;
  dpi = 192;
  userName = "gean";
in {
  config = {
    home-manager.users.${userName} = {
      xresources.properties = lib.mkIf (isHidpi) {
        "Xft.dpi" = dpi;
        "Xft.antialias" = 1;
        "Xft.rgba" = "rgb";
      };
    };

    environment.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "0";
      QT_FONT_DPI = "96";
      QT_SCALE_FACTOR = "2";

      GDK_DPI_SCALE = "0.5";
      GDK_SCALE = "2";

      BSPWM_GAP = "25";
    };
  };
}
