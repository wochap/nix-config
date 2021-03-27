{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  config = {
    home-manager.users.gean = {
      home.packages = with pkgs; [
        rofi-calc
      ];

      # Setup dotfiles
      home.file = {
        ".config/rofi-theme.rasi".source = ./dotfiles/rofi-theme.rasi;
      };

      programs.rofi = {
        enable = true;
      };

      services.dunst = {
        enable = true;
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
          # TODO: add missing icons to WhiteSur-dark
          # name = "WhiteSur-dark";
          # package = localPkgs.whitesur-dark-icons;
        };
        settings = (import ./dotfiles/dunstrc.nix);
      };

      services.redshift = {
        enable = true;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };

      # screenshot utility
      services.flameshot.enable = true;
    };
  };
}
