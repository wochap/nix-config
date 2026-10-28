{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.lang-nix;
  nix-sync-all = pkgs.writeScriptBin "nix-sync-all" (builtins.readFile ./scripts/nix-sync-all.sh);
in
{
  options._custom.programs.lang-nix.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # required by personal nvim config
      statix # nvim-lint
      nixfmt # conform.nvim
      nixd # lsp server
      nix-sync-all
    ];
  };
}
