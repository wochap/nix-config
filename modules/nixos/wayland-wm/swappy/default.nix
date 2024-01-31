{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs;
        [
          swappy # image editor
        ];
    };

    home-manager.users.${userName} = {
      xdg.configFile."swappy/config".source = ./dotfiles/config;
    };
  };
}
