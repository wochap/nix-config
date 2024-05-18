{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.tools;
in {
  options._custom.dev.tools.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        ansible # automation scripts
        awscli
        mkcert # create certificates (HTTPS)
        ngrok # expose web server
        stripe-cli
        watchman # required by react native
      ];
    };
  };
}
