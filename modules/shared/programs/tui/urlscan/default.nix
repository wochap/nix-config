{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.urlscan;
in {
  options._custom.programs.urlscan.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ urlscan ];

      xdg.configFile."urlscan/config.json".source = ./dotfiles/config.json;
    };
  };
}
