{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-go;
in {
  options._custom.dev.lang-go.enable = lib.mkEnableOption { };

  config =
    lib.mkIf cfg.enable { environment.systemPackages = with pkgs; [ go ]; };
}

