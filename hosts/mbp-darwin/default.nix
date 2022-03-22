# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gmbp";
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  draculaTheme = import ../../config/mixins/dracula.nix;
in
{
  imports = [
    ../../config/macos.nix
  ];

  config = {
    _userName = userName;
    _homeDirectory = "/Users/${userName}";
    _configDirectory = configDirectory;
    _theme = draculaTheme;

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
    home-manager.users.${userName}.home.stateVersion = "21.11";
  };
}

