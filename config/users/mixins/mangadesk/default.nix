{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../packages { inherit pkgs lib; };
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/mangadesk";
in {
  config = {
    home-manager.users.${userName} = {
      home.packages = [ localPkgs.mangadesk ];

      xdg.configFile = {
        "mangadesk/config.json".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.json";
      };
    };
  };
}
