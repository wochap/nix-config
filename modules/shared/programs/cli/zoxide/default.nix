{ config, lib, ... }:

let cfg = config._custom.cli.zoxide;
in {
  options._custom.cli.zoxide.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        options = [ ];
      };
    };
  };
}
