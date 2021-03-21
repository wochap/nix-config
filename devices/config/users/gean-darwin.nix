{ config, lib, pkgs, ... }:

{
  imports = [
    ./config/default-darwin.nix
  ];

  config = {
    home-manager.users.gean = {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = "gean";
      home.homeDirectory = "/home/gean";
    };
  };
}
