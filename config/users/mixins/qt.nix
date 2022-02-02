{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
in {
  config = {
    environment = {
      systemPackages = with pkgs;
        [
          qt5.qtgraphicaleffects # required by gddm themes
        ] ++ (if isWayland then [ qt5.qtwayland ] else [ ]);
      variables = lib.mkMerge [
        (lib.mkIf isWayland {
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORM = "wayland";
        })
      ];
    };

    home-manager.users.${userName} = {
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
