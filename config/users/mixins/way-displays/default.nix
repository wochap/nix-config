{ config, pkgs, lib, libAttr, ... }:

let
  localPkgs = import ../../../packages {
    pkgs = pkgs;
    lib = lib;
  };
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/way-displays";
in {
  config = {
    environment = { systemPackages = with pkgs; [ localPkgs.way-displays ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "way-displays/cfg.yaml".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/cfg.yaml";
      };
    };
  };
}

