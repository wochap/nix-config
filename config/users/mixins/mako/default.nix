{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/mako";
in {
  config = {
    environment = {
      systemPackages = with pkgs; [ mako libnotify dunst ];
      etc = {
        "assets/notification.flac" = {
          source = ../dunst/assets/notification.flac;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "mako/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
      };
    };
  };
}

