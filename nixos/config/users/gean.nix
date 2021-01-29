{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    # Include configuration
    ./config/default.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gean";
  home.homeDirectory = "/home/gean";
}
