{ config, lib, ... }:

let inherit (config._custom.globals) configDirectory;
in {
  config = {
    _custom.hm = {
      xdg.configFile = {
        "secrets".source =
          lib._custom.mkOutOfStoreSymlink "${configDirectory}/secrets";
      };
    };
  };
}
