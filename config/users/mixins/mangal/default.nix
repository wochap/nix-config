{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = [ pkgs.mangal ];

      xdg.configFile = {
        "mangal/mangal.toml".source = ./dotfiles/mangal.toml;
      };
    };
  };
}
