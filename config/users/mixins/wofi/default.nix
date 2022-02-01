{ config, pkgs, lib, ... }:

let
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/wofi";
in {
  config = {
    environment = {
      systemPackages = with pkgs; [ wofi ];

      etc = {
        "scripts/wofi-wifi.sh" = {
          source = ./scripts/wofi-wifi.sh;
          mode = "0755";
        };
        "scripts/wofi-clipboard.sh" = {
          source = ./scripts/wofi-clipboard.sh;
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
            (key: value: "@define-color ${key} ${value};") theme)}
        '';
      };
    };
  };
}

