{ config, lib, ... }:

let cfg = config._custom.programs.nix-direnv;
in {
  options._custom.programs.nix-direnv.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
