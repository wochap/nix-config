{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    ./config/common.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gean";
  home.homeDirectory = "/home/gean";
}
