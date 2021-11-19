{ config, lib, pkgs, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./nix-common.nix
    ./config/macos.nix
  ];

  config = {
    nix.gc.user = userName;

    users.users.${userName} = {
      home = "/Users/${userName}";
    };

    home-manager.users.${userName} = {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = userName;
      home.homeDirectory = "/Users/${userName}";
    };
  };
}
