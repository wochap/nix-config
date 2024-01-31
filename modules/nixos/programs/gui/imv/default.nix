{ config, pkgs, lib, ... }:

let
  cfg = config._custom.gui.imv;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.gui.imv = { enable = lib.mkEnableOption { }; };

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
