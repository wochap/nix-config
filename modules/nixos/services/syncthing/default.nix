{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.syncthing;
  inherit (config._custom.globals) userName homeDirectory;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-gate.proxies.syncthing;
  # GUI login shared by every host; the password is plaintext, syncthing hashes it
  syncthingUserName = "wochap";
  guiPasswordFile = config.sops.secrets.local-syncthing-password.path;
in
{
  options._custom.services.syncthing = {
    enable = lib.mkEnableOption { };
    # headless host: system service (no lingering, no web-gate), GUI and sync
    # port only reachable over the tailnet
    tailnetOnly = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sops.secrets.local-syncthing-password = {
          sopsFile = ../../../../secrets-sops/local.yaml;
          owner = userName;
        };
      }

      (lib.mkIf (!cfg.tailnetOnly) {
        # https://syncthing.wochap.local
        _custom.services.web-gate.proxies.syncthing = {
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
            guiCredentials = {
              username = syncthingUserName;
              passwordFile = guiPasswordFile;
            };
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
      })

      (lib.mkIf cfg.tailnetOnly {
        # http://<tailnet ip>:8384
        services.syncthing = {
          enable = true;
          user = userName;
          group = "users";
          # base for new folders (~/Sync), keeps synced files in the user's home
          dataDir = homeDirectory;
          configDir = "${homeDirectory}/.local/state/syncthing";
          # firewall limits it to tailscale0
          guiAddress = "0.0.0.0:8384";
          # settings != {} triggers syncthing-init, keep folders/devices added via GUI
          overrideDevices = false;
          overrideFolders = false;
          settings.gui.user = syncthingUserName;
          inherit guiPasswordFile;
          settings.options = {
            urAccepted = -1;
            # no LAN on the VPS
            localAnnounceEnabled = false;
            # relays would let peers reach it around the tailnet-only firewall
            relaysEnabled = false;
          };
        };
        systemd.services.syncthing-init.serviceConfig.TimeoutStartSec = "60s";

        networking.firewall.interfaces.tailscale0 = {
          allowedTCPPorts = [
            8384
            22000
          ];
          allowedUDPPorts = [ 22000 ];
        };
      })
    ]
  );
}
