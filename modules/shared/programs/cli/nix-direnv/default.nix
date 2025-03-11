{ config, lib, ... }:

let cfg = config._custom.programs.nix-direnv;
in {
  options._custom.programs.nix-direnv.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      # silent direnv
      home.sessionVariables."DIRENV_LOG_FORMAT" = "";

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableBashIntegration = true;
        enableZshIntegration = config._custom.programs.zsh.enable;
      };
    };
  };
}
