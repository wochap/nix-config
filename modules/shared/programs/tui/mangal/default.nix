{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.mangal;
in {
  options._custom.programs.mangal.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [ pkgs.mangal ];

      xdg.configFile = {
        "mangal/mangal.toml".source = ./dotfiles/mangal.toml;
      };
    };
  };
}
