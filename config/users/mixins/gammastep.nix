{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
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
