{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  inherit (config._custom.globals) themeColors;
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ imv ];

      xdg.configFile = {
        "imv/config".text = lib.generators.toINI { } {
          options = {
            inherit (themeColors) background;
          };
        };
      };
    };
  };
}
