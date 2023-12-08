{ config, lib, ... }:

let
  cfg = config._custom.services.syncthing;
  userName = config._userName;
in {
  options._custom.services.syncthing = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {

      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        relay.enable = false;
        settings.options = {
          urAccepted = -1;
          # globalDiscoveryEnabled = false;
        };
      };
    };
  };
}
