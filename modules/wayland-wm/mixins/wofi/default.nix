{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/wofi";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ wofi ];

      etc = {
        "scripts/wofi-wifi.sh" = {
          source = ./scripts/wofi-wifi.sh;
          mode = "0755";
        };
        "scripts/wofi-launcher.sh" = {
          source = ./scripts/wofi-launcher.sh;
          mode = "0755";
        };
        "scripts/wofi-powermenu.sh" = {
          source = ./scripts/wofi-powermenu.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "wofi/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
        "wofi/style.css".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
        "wofi/colors".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/colors";
        "wofi/colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") themeColors)}
        '';
      };
    };
  };
}
