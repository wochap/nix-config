{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../packages { inherit pkgs lib; };
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = [ localPkgs.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source = ./dotfiles/config.json;
      };
    };
  };
}
