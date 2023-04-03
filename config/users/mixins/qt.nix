{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
in {
  config = {
    environment = {
      systemPackages = with pkgs;
        [
          qt5ct
          libsForQt5.oxygen
          libsForQt5.oxygen-icons5
          libsForQt5.breeze-qt5
          libsForQt5.breeze-icons

          qt5.qtgraphicaleffects # required by gddm themes
        ] ++ (if isWayland then [ qt5.qtwayland qt6.qtwayland ] else [ ]);
      variables = lib.mkMerge [
        {
          QT_QPA_PLATFORMTHEME = "qt5ct";

          # XDG_CURRENT_DESKTOP = "KDE";
          DESKTOP_SESSION = "KDE";
        }
        (lib.mkIf isWayland {
          # QT_WAYLAND_FORCE_DPI = "physical";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORM = "wayland";
        })
      ];
    };

    home-manager.users.${userName} = {
      # qt = {
      #   enable = true;
      #   platformTheme = "gnome";
      #   style = {
      #     package = pkgs.unstable.adwaita-qt;
      #     name = "adwaita-dark";
      #   };
      # };
    };
  };
}
