{ config, pkgs, lib, ... }:

let cfg = config._custom.tui.nix-direnv;
in {
  options._custom.tui.nix-direnv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
