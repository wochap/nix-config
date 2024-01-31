{ config, ... }:

let
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._custom.globals.configDirectory;
in {
  config = {
    _custom.hm = {
      xdg.configFile = {
        "secrets".source = mkOutOfStoreSymlink "${configDirectory}/secrets";
      };
    };
  };
}
