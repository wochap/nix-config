{ config, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._custom.globals.configDirectory;
in {
  config = {
    home-manager.users.${userName} = {
      xdg.configFile = {
        "secrets".source = mkOutOfStoreSymlink "${configDirectory}/secrets";
      };
    };
  };
}
