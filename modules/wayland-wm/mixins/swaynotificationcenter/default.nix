{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory =
    "${configDirectory}/modules/wayland-wm/mixins/swaynotificationcenter";
in {
  config = lib.mkIf false {
  # config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        swaynotificationcenter = prev.swaynotificationcenter.overrideAttrs (oldAttrs: rec {
          src = prev.fetchFromGitHub {
            owner = "ErikReider";
            repo = "SwayNotificationCenter";
            rev = "9f6cd8716d6bf2a1eb38eb3db710c0ad91ca3274";
            hash = "sha256-kriLaGXOqXwcGxTDKMEVOSgLdFeErSroxAiCcYfVe+U=";
          };
        });
      })
    ];

    # so it propagates to:
    # /run/current-system/sw/share/icons/Numix-Square
    environment = {
      systemPackages = with pkgs; [ numix-icon-theme-square gnome-icon-theme ];
      etc."xdg/swaync".source = "${pkgs.swaynotificationcenter}/etc/xdg/swaync";
    };

    home-manager.users.${userName} = {
      home.packages = with pkgs; [ swaynotificationcenter libnotify dunst ];

      xdg.configFile = {
        "swaync/config.json".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.json";
        "swaync/style.css".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
      };
    };
  };
}
