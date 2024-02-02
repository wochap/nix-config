{ config, lib, ... }:

let cfg = config._custom.services.syncthing;
in {
  options._custom.services.syncthing.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        relay.enable = false;
        settings.options = {
          urAccepted = -1;
          globalDiscoveryEnabled = false;
        };
      };
    };
  };
}
