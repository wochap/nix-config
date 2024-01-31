{ config, lib, ... }:

let
  cfg = config._custom.waylandWm;

  jsonRAW = builtins.readFile ./dotfiles/config.json;
  parsedJson = builtins.fromJSON jsonRAW;
in {
  config = lib.mkIf cfg.enable {

    _custom.hm = {
      _custom.programs.waybar = {
        enable = true;
        settings = { mainBar = parsedJson; };
      };
    };
  };
}
