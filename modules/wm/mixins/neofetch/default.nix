{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/neofetch";
in {
  config = {
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
