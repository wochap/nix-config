{ config, pkgs, lib, _customLib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {

      home.packages = with pkgs; [ yambar ];

      xdg.configFile."yambar/config.yml".source =
        relativeSymlink ./dotfiles/config.yml;
    };
  };
}

