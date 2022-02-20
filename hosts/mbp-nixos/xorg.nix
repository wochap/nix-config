{ config, pkgs, lib, inputs, ... }:

{
  config = {
    environment.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # QT_AUTO_SCREEN_SCALE_FACTOR = "0";
      # QT_FONT_DPI = "96";
      # QT_SCALE_FACTOR = "2";

      BSPWM_GAP = "25";
    };
  };
}
