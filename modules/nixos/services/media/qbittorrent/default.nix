{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "qbittorrent";
  vpnName = "vpn";
  svc = cfg.services.qbittorrent;
  vpn = svc.vpn;
  webPort = 8080;
  vpnService = "${common.serviceName vpnName}.service";
  vpnSopsSecret = "media-vpn-env";
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers = {
      ${common.containerName name} = {
        image = cfg.images.qbittorrent;
        user = common.user;
        environment = common.umaskEnv // {
          QBT_WEBUI_PORT = toString webPort;
        };
        volumes = [
          "${common.stateDir name}:/config:rw"
          (common.dataMount "torrents")
        ];
        extraOptions =
          common.hardening
          ++ [
            "--read-only"
            "--pids-limit=1024"
          ]
          # With the VPN on, qBittorrent lives in gluetun's network namespace and
          # has no interface of its own. Ports are then published by gluetun.
          ++ lib.optional vpn.enable "--network=container:${common.containerName vpnName}";
      }
      // lib.optionalAttrs (!vpn.enable) {
        networks = [ cfg.network.name ];
        ports = common.publish svc webPort;
      }
      // lib.optionalAttrs vpn.enable {
        dependsOn = [ (common.containerName vpnName) ];
      };

      ${common.containerName vpnName} = lib.mkIf vpn.enable {
        image = cfg.images.gluetun;
        networks = [ cfg.network.name ];
        ports = common.publish svc webPort;
        environment = {
          TZ = common.umaskEnv.TZ;
          # Let the other containers reach the qBittorrent web UI through
          # gluetun's firewall.
          FIREWALL_INPUT_PORTS = toString webPort;
          FIREWALL_OUTBOUND_SUBNETS = cfg.network.subnet;
        }
        // vpn.environment;
        environmentFiles =
          lib.optional (vpn.sopsKey != null) config.sops.secrets.${vpnSopsSecret}.path
          ++ vpn.environmentFiles;
        devices = [ "/dev/net/tun" ];
        capabilities.NET_ADMIN = true;
        extraOptions = [
          "--cap-drop=all"
          "--security-opt=no-new-privileges"
          "--pids-limit=256"
        ]
        ++ vpn.extraOptions;
      };
    };

    sops.secrets.${vpnSopsSecret} = lib.mkIf (vpn.enable && vpn.sopsKey != null) {
      sopsFile = ../../../../../secrets-sops/local.yaml;
      key = vpn.sopsKey;
      mode = "0400";
      restartUnits = [ vpnService ];
    };

    systemd.services = {
      ${common.serviceName name} = common.mkSystemdService name {
        extra = lib.optionalAttrs vpn.enable {
          # A restarted gluetun gets a new namespace; restart qBittorrent with it.
          bindsTo = [ vpnService ];
          after = [ vpnService ];
        };
      };
      ${common.serviceName vpnName} = lib.mkIf vpn.enable (
        common.mkSystemdService vpnName { timeoutStop = 30; }
      );
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;
  };
}
