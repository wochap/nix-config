{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      services.syncthing = { enable = true; };
    };
  };
}
