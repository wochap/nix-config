{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/mangadesk";
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = with pkgs; [ _custom.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.json";
      };
    };
  };
}
