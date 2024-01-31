{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gammastep ];

    home-manager.users.${userName} = {
      services.gammastep = {
        enable = true;
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
