{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.imv;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.imv.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ imv ];

      xdg.configFile = {
        "imv/config".text = lib.generators.toINI { } {
          options = { inherit (themeColors) background; };
        };
      };
    };
  };
}
