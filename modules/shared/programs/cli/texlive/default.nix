{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.texlive;
in {
  options._custom.programs.texlive.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      texlive.combined.scheme-full
      pandoc
      biber
    ];
  };
}
