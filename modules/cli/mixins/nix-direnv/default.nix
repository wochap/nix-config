{ config, lib, ... }:

let cfg = config._custom.cli.nix-direnv;
in {
  options._custom.cli.nix-direnv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
