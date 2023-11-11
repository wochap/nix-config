{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.neofetch;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wm/mixins/neofetch";
in {
  options._custom.wm.neofetch = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch

      # Image preview on terminal
      w3m
      imagemagick
    ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "neofetch/config.conf".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.conf";
      };
    };
  };
}
