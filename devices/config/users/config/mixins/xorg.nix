{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../../packages { pkgs = pkgs; };
  isHidpi = config._isHidpi;
in
{
  imports = [
    ./dunst
  ];

  config = {
    home-manager.users.gean = {
      home.packages = with pkgs; [
        rofi-calc
      ];

      # Setup dotfiles
      home.file = {
        ".config/rofi-theme.rasi".source = ../dotfiles/rofi-theme.rasi;
      };

      xresources.properties = lib.mkIf isHidpi {
        "Xft.dpi" = 144;
        "Xcursor.size" = 40;
      };

      programs.rofi = {
        enable = true;
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
