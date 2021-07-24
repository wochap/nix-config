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

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home-manager.users.gean.home.stateVersion = "21.03";
  };
}
