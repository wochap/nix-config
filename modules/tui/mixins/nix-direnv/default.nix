{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.nixDirenv;
  userName = config._userName;
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
