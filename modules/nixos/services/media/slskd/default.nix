{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "slskd";
  vpnName = "vpn";
  svc = cfg.services.slskd;
  webPort = 5030;
  vpnService = "${common.serviceName vpnName}.service";
  credentialsSecret = "media-soulseek-env";
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.slskd;
      user = common.user;
      environment = {
        inherit (common.umaskEnv) TZ;
        # slskd applies its own umask, not UMASK.
        SLSKD_UMASK = "0002";
        SLSKD_HTTP_PORT = toString webPort;
        SLSKD_NO_HTTPS = "true";
        SLSKD_SLSK_LISTEN_PORT = toString svc.listenPort;
        SLSKD_DOWNLOADS_DIR = "/data/soulseek/downloads";
        SLSKD_INCOMPLETE_DIR = "/data/soulseek/incomplete";
        # Peers often refuse users who share nothing; share the library.
        SLSKD_SHARED_DIR = "/data/media/music";
      };
      environmentFiles =
        lib.optional common.declarative (common.apiKeyEnvFile name)
        ++ lib.optional (svc.credentials.sopsFile != null) config.sops.secrets.${credentialsSecret}.path;
      volumes = [
        "${common.stateDir name}:/app:rw"
        (common.dataMount "soulseek")
        (common.dataMountRo "media/music")
      ];
      # Not --read-only: the single-file .NET binary unpacks itself into /.net.
      extraOptions =
        common.hardening
        ++ [ "--pids-limit=512" ]
        # With the VPN on, slskd lives in gluetun's network namespace, like
        # qBittorrent. gluetun then publishes the web UI.
        ++ lib.optional svc.vpn "--network=container:${common.containerName vpnName}";
    }
    // lib.optionalAttrs (!svc.vpn) {
      networks = [ cfg.network.name ];
      ports = common.publish svc webPort ++ [
        "${toString svc.listenPort}:${toString svc.listenPort}"
      ];
    }
    // lib.optionalAttrs svc.vpn {
      dependsOn = [ (common.containerName vpnName) ];
    };

    # SLSKD_API_KEY from SOPS, and the web login from the shared admin login.
    sops.templates = lib.mkIf common.declarative {
      "media-${name}.env" = {
        mode = "0400";
        restartUnits = [ "${common.serviceName name}.service" ];
        content = ''
          SLSKD_API_KEY=${config.sops.placeholder.${cfg.declarative.apiKeys.${name}.sopsKey}}
          SLSKD_USERNAME=${cfg.declarative.admin.username}
          SLSKD_PASSWORD=${config.sops.placeholder.${cfg.declarative.admin.passwordSecret.sopsKey}}
        '';
      };
    };

    sops.secrets.${credentialsSecret} = lib.mkIf (svc.credentials.sopsFile != null) {
      inherit (svc.credentials) sopsFile;
      key = svc.credentials.sopsKey;
      mode = "0400";
      restartUnits = [ "${common.serviceName name}.service" ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name {
      extra = lib.optionalAttrs svc.vpn {
        # A restarted gluetun gets a new namespace; restart slskd with it.
        bindsTo = [ vpnService ];
        after = [ vpnService ];
      };
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;
  };
}
