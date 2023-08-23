{ config, pkgs, lib, libAttr, ... }:

let
  cfg = config._custom.waylandWm;
  localPkgs = import ../../../../config/packages { inherit pkgs lib; };
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory =
    "${configDirectory}/modules/wayland-wm/mixins/way-displays";
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
