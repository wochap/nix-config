{ config, pkgs, lib, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
in
{
  config = {
    environment = {
      systemPackages = [
        localPkgs.eww # custom widgets daemon
      ];

      etc = {
        "blop.wav" = {
          source = ./assets/blop.wav;
          mode = "0755";
        };

        # "eww_bright.sh" = {
        #   source = ./scripts/eww_bright.sh;
        #   mode = "0755";
        # };
        "eww_vol.sh" = {
          source = ./scripts/eww_vol.sh;
          mode = "0755";
        };
        "eww_vol_close.sh" = {
          source = ./scripts/eww_vol_close.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.gean = {
      home.file = {
        ".config/eww".source = ./dotfiles/eww;
      };
    };
  };
}
