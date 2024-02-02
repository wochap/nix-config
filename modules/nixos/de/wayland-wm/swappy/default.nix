{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ swappy ];

      xdg.configFile."swappy/config".source = ./dotfiles/config;
    };
  };
}
