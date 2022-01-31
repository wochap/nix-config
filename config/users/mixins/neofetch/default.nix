
{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      neofetch

      # Image preview on terminal
      w3m
      imagemagick
    ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "neofetch/config.conf".source = ./dotfiles/config.conf;
      };
    };
  };
}
