{ config, pkgs, lib, inputs, ... }:

{
  config = {
    environment.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      BSPWM_GAP = "25";
    };
  };
}

