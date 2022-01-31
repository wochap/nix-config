{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/mako";
in {
  config = {
    environment = { systemPackages = with pkgs; [ mako libnotify ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "mako/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
      };
    };
  };
}

