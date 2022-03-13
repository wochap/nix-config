{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
in {
  config = {
    home-manager.users.${userName} = {
      home.symlinks.".config/secrets" = "${configDirectory}/secrets";
    };
  };
}
