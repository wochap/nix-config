{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-rust;
in {
  options._custom.programs.lang-rust.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ rustc cargo cargo-tauri ];
  };
}

