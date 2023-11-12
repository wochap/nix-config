{ config, lib, ... }:

let
  cfg = config._custom.cli.zoxide;
  userName = config._userName;
in {
  options._custom.cli.zoxide = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        options = [ ];
      };
    };
  };
}
