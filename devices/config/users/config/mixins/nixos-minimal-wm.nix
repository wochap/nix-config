{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
      services.redshift = {
        enable = true;
        package = if isWayland then pkgs.redshift-wlr else pkgs.redshift;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };
    };
  };
}
