# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gmbp";
in
{
  imports = [
    ./config/macos.nix
  ];

  config = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;
  };
}
