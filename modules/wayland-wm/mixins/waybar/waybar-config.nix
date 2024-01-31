{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;

  jsonRAW = builtins.readFile ./dotfiles/config.json;
  parsedJson = builtins.fromJSON jsonRAW;
in {
  config = lib.mkIf cfg.enable {

    home-manager.users.${userName} = {
      _custom.programs.waybar = {
        enable = true;
        settings = { mainBar = parsedJson; };
      };
    };
  };
}
