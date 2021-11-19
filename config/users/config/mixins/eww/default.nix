{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    environment = {
      systemPackages = with pkgs; if (isWayland) then [
        eww-wayland
      ] else [
        eww
      ];

      etc = {
        "assets/blop.wav" = {
          source = ./assets/blop.wav;
          mode = "0755";
        };

        # "scripts/eww_bright.sh" = {
        #   source = ./scripts/eww_bright.sh;
        #   mode = "0755";
        # };
        # "scripts/eww_vol.sh" = {
        #   source = ./scripts/eww_vol.sh;
        #   mode = "0755";
        # };
        "scripts/eww_vol_listen.sh" = {
          source = ./scripts/eww_vol_listen.sh;
          mode = "0755";
        };
        "scripts/eww_vol_close.sh" = {
          source = ./scripts/eww_vol_close.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "eww".source = ./dotfiles/eww;
      };
    };
  };
}
