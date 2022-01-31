{ config, pkgs, ... }:

let
  userName = config._userName;
  homeDirectory = config._homeDirectory;
in {
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${userName} = {
      home = homeDirectory;
      shell = pkgs.zsh;
      uid = 1000;
    };

    home-manager.users.${userName} = {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = userName;
      home.homeDirectory = homeDirectory;
    };
  };
}

