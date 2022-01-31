{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/wofi";
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [ wofi ];

      etc = {
        "scripts/wofi-clipboard.sh" = {
          source = ./scripts/wofi-clipboard.sh;
          mode = "0755";
        };
      };

    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "wofi/config".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
        "wofi/style.css".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
      };
    };
  };
}

