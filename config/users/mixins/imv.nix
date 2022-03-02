{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  theme = config._theme;
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ imv ];

      xdg.configFile = {
        "imv/config".text = lib.generators.toINI { } {
          options = {
            background = theme.background;
          };
        };
      };
    };
  };
}
