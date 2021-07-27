{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; };
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
        anki # mnemonic tool

        # APPS MEDIA (Comment on first install)
        inkscape # photo editor cli/gui
        # kdeApplications.kdenlive # video editor
        # nomacs # image viewer/editor
        obs-studio # video capture
        # olive-editor # video editor
        # openshot-qt # video editor

        # Themes
        adwaita-qt

        # Themes settings
        libsForQt5.qtstyleplugins
        qgnomeplatform
        qt5.qtgraphicaleffects # required by gddm themes
        qt5ct
      ] ++ [
        localPkgs.stremio
      ];
    };
  };
}
