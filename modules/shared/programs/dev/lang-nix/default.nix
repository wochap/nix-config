{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-nix;
in {
  options._custom.programs.lang-nix.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # required by personal nvim config
      statix # nvim-lint
      nixfmt-classic # conform.nvim
      nixd # lsp server
    ];
  };
}
