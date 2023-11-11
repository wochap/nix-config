{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.mangal;
  userName = config._userName;
in {
  options._custom.tui.mangal = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = [ pkgs.mangal ];

      xdg.configFile = {
        "mangal/mangal.toml".source = ./dotfiles/mangal.toml;
      };
    };
  };
}
