{ config, pkgs, lib, ... }:

let
  cfg = config._custom.gui.imv;
  userName = config._userName;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.gui.imv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ imv ];

      xdg.configFile = {
        "imv/config".text = lib.generators.toINI { } {
          options = { inherit (themeColors) background; };
        };
      };
    };
  };
}
