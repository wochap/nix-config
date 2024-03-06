{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.mangadesk;
in {
  options._custom.programs.mangadesk.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ _custom.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source = ./dotfiles/config.json;
      };
    };
  };
}
