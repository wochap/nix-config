{ config, lib, ... }:

let cfg = config._custom.programs.zoxide;
in {
  options._custom.programs.zoxide.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = config._custom.programs.zsh.enable;
        options = [ ];
      };
    };
  };
}
