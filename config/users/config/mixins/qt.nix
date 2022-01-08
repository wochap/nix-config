{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  isHidpi = config._isHidpi;
  isWayland = config._displayServer == "wayland";
in {
  config = {
    environment = {
      systemPackages = with pkgs;
        [
          qt5.qtgraphicaleffects # required by gddm themes
        ] ++ (if isWayland then [ qt5.qtwayland ] else [ ]);
    };

    home-manager.users.${userName} = {
      home.sessionVariables = lib.mkMerge [
        (lib.mkIf isHidpi {
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          QT_FONT_DPI = "96";
          QT_SCALE_FACTOR = "1.5";
        })
      ];

      qt = {
        enable = true;
        platformTheme = "gnome";
        style = {
          package = pkgs.adwaita-qt;
          name = "adwaita";
        };
      };
    };
  };
}
