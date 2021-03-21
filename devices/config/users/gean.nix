{ config, pkgs, ... }:

let
  isDarwin = config._displayServer == "darwin";
in
{
  imports = [
    # Include configuration
    if isDarwin then ./config/default-darwin.nix else ./config/default.nix
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
