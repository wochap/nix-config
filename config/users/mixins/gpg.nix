{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        pinentryFlavor = "gnome3";
      };
    };
  };
}

