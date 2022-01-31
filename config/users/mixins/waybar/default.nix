{ config, pkgs, lib, ... }:

let
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/waybar";
in {
  config = {
    environment.systemPackages = with pkgs; [ waybar ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "waybar/config".source = mkOutOfStoreSymlink ./dotfiles/config.json;
        "waybar/style.css".source = mkOutOfStoreSymlink ./dotfiles/style.css;
      };
    };
  };
}
