{ config, pkgs, lib, libAttr, ... }:

let
  cfg = config._custom.xorgWm;
  localPkgs = import ../../../packages {
    pkgs = pkgs;
    lib = lib;
  };
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/way-displays";
in {
  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ localPkgs.way-displays ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "way-displays/cfg.yaml".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/cfg.yaml";
      };
    };
  };
}

