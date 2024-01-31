{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.gpg;
  userName = config._userName;
in {
  options._custom.cli.gpg = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {

    home-manager.users.${userName} = {

      programs.gpg.enable = true;
    };

  };
}
