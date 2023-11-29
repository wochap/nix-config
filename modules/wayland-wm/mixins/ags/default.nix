{ config, pkgs, lib, inputs, _customLib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);
  inherit (config._custom.globals) themeColors;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [
          inputs.ags.packages.${pkgs.system}.default
          sassc
        ];
      };

      xdg.configFile = {
        "ags" = {
          source = relativeSymlink ./dotfiles/ags;
          recursive = true;
        };
      };
    };
  };
}
