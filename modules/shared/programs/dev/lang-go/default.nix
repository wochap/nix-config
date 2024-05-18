{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-go;
in {
  options._custom.programs.lang-go.enable = lib.mkEnableOption { };

  config =
    lib.mkIf cfg.enable { environment.systemPackages = with pkgs; [ go ]; };
}

