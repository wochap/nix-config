{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.tools;
in {
  options._custom.dev.tools.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {

      home.packages = with pkgs; [ awscli ];
    };
  };
}
