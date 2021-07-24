{ config, lib, pkgs, ... }:

{
  imports = [
    ./nix-common.nix
    ./config/macos.nix
  ];

  config = {
    users.users.gean = {
      home = "/Users/gean";
    };

    home-manager.users.gean = {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = "gean";
      home.homeDirectory = "/Users/gean";
    };
  };
}
