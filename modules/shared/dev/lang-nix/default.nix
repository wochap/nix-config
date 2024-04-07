{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-nix;
in {
  options._custom.dev.lang-nix.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # required by personal nvim config
      statix # nvim-lint
      nixfmt # conform.nvim
    ];
  };
}
