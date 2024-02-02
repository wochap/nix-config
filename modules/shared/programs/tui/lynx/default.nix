{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lynx;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in {
  options._custom.programs.lynx.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [ lynx ];
        sessionVariables = {
          LYNX_CFG = "${hmConfig.xdg.configHome}/lynx/lynx.cfg";
          LYNX_LSS = "${hmConfig.xdg.configHome}/lynx/lynx.lss";
        };
      };

      xdg.configFile."lynx/lynx.cfg".source = ./dotfiles/lynx.cfg;
      xdg.configFile."lynx/lynx.lss".source = ./dotfiles/lynx.lss;
    };
  };
}
