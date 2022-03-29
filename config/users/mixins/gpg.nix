{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {

    home-manager.users.${userName} = {

      programs.gpg.enable = true;
    };

  };
}
