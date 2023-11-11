{ config, pkgs, lib, ... }:

let cfg = config._custom.tui.nixDirenv;
in {
  options._custom.tui.nixDirenv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
