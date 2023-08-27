{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.qt;
  userName = config._userName;
in {
  options._custom.wm.qt = {
    enable = lib.mkEnableOption "setup qt theme and apps";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        # kvantum (not required but...)
        libsForQt5.qtstyleplugins
        libsForQt5.qtstyleplugin-kvantum

        # fix kirigami apps look
        # for example in filelight, without it the app looks weird
        # https://github.com/NixOS/nixpkgs/pull/202990#issuecomment-1328068486
        libsForQt5.qqc2-desktop-style
        libsForQt5.qqc2-breeze-style # required?

        libsForQt5.qt5.qtwayland

        lightly-qt
        libsForQt5.breeze-icons
        libsForQt5.breeze-qt5

        # required for some QT apps
        libsForQt5.kirigami2
        libsForQt5.kirigami-addons
        libsForQt5.kirigami-gallery
      ];
      variables = {
        DESKTOP_SESSION = "KDE";
        # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
      };
    };

    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    home-manager.users.${userName} = {
      qt = {
        enable = true;
        # the following options requires unstable nixpkgs
        # platformTheme = "qtct";
      };

      # HACK: only home manager unstable supports qtct as platformTheme
      home.sessionVariables = { QT_QPA_PLATFORMTHEME = "qt5ct"; };
      home.packages = [ pkgs.libsForQt5.qt5ct ];
      xsession.importedVariables = [ "QT_QPA_PLATFORMTHEME" ];
    };
  };
}
