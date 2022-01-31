{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        alacritty
      ];
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "alacritty/alacritty.yml".source = ./dotfiles/alacritty.yml;
      };
    };
  };
}
