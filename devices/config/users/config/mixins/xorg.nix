{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
in
{
  imports = [
    ./dunst
    ./rofi
  ];

  config = {
    home-manager.users.gean = {
      xresources.properties = lib.mkIf isHidpi {
        "Xft.dpi" = 144;
        "Xcursor.size" = 40;
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
