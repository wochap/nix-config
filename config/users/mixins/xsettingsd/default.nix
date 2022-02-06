{ config, lib, pkgs, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/xsettingsd";
in {
  config = {
    environment = { systemPackages = with pkgs; [ xsettingsd ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "xsettingsd/xsettingsd.conf".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/xsettingsd.conf";
      };
    };
  };
}

