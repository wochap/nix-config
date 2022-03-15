{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      programs.lsd = {
        enable = true;
        # adds ls ll la lt ll
        enableAliases = true;
        settings = {
          sorting = { dir-grouping = "first"; };
          symlink-arrow = "->";
        };
      };
    };
  };
}
