{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
in
{
  config = {
    environment = {
      sessionVariables = lib.mkMerge [
        {
          QT_QPA_PLATFORMTHEME = "qt5ct";
        }
        (lib.mkIf isHidpi {
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          QT_FONT_DPI = "96";
          QT_SCALE_FACTOR = "1.5";
        })
      ];
      systemPackages = with pkgs; [
        # Themes
        adwaita-qt

        # Themes settings
        libsForQt5.qtstyleplugins
        qgnomeplatform
        qt5.qtgraphicaleffects # required by gddm themes
        qt5ct
      ];
    };
  };
}
