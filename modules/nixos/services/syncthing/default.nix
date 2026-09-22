{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.syncthing;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-proxies.syncthing;
in
{
  options._custom.services.syncthing.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # https://syncthing.wochap.local
    _custom.services.web-proxies.syncthing = {
      enable = true;
      subdomain = "syncthing";
      publicPort = 8383;
      backendPort = 8384;
      # keep syncthing always running, nginx hits backendPort directly
      lazy = false;
    };

    _custom.hm = {
      services.syncthing = {
        enable = true;
        guiAddress = "${wochap-ssc.meta.address}:${toString proxy.backendPort}";
        # nginx forwards Host as syncthing.wochap.local, syncthing rejects
        # non-localhost hosts unless this is set
        settings.gui.insecureSkipHostcheck = true;
        # settings != {} triggers syncthing-init, keep folders/devices added via GUI
        overrideDevices = false;
        overrideFolders = false;
        # openDefaultPorts = true;
        # relay.enable = false;
        # settings.options = {
        #   urAccepted = -1;
        #   globalDiscoveryEnabled = false;
        # };
      };
      # syncthing-init polls the GUI port once a second for ~17 minutes
      # before giving up; switch-to-configuration waits on it. Cap it.
      systemd.user.services.syncthing-init.Service.TimeoutStartSec = "60s";
    };
  };
}
