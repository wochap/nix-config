{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/mixins/ags";
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
          source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/ags";
          recursive = true;
        };
      };
    };
  };
}
