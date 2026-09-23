{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  ocfg = cfg.openDesign;
  inherit (pkgs._custom) wochap-ssc;
  source = inputs."open-design";
  revision = source.rev or (throw "The open-design flake input must be locked to a Git revision");
  ociBackend = config.virtualisation.oci-containers.backend;
  serviceName = "${ociBackend}-open-design";
  proxy = config._custom.services.web-proxies.open-design;
  # The upstream image runs as USER open-design (1001:1001).
  uid = 1001;
  gid = 1001;
  dataDir = "/var/lib/open-design";
in
{
  options._custom.services.ai.openDesign = {
    enable = lib.mkEnableOption "Open Design";

    model = lib.mkOption {
      type = lib.types.str;
      default = "open-design";
      description = ''
        OmniRoute combo that Open Design uses as its text model. The BYOK
        settings live in browser localStorage, so enter this value in
        Settings → Models & providers (see README.md).
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Extra environment for the container, such as media-provider API keys.";
    };

    memoryLimitMb = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = ''
        V8 old-space limit (NODE_OPTIONS=--max-old-space-size). The upstream
        default of 192 MB is tight for exports.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && ocfg.enable) {
    assertions = [
      {
        assertion = cfg.enableOmniRoute;
        message = "_custom.services.ai.openDesign requires enableOmniRoute.";
      }
    ];

    _custom.services.local-oci-images.open-design = {
      inherit source;
      tag = revision;
      dockerfile = "deploy/Dockerfile";
    };

    _custom.services.web-proxies.open-design = {
      enable = true;
      subdomain = "open-design";
      inherit serviceName;
      publicPort = 20400;
      backendPort = 20401;
      lazy = true;
    };

    virtualisation.oci-containers.containers.open-design = {
      inherit serviceName;
      volumes = [ "${dataDir}:/app/.od:rw" ];
      environment = {
        NODE_ENV = "production";
        NODE_OPTIONS = "--max-old-space-size=${toString ocfg.memoryLimitMb}";
        OD_BIND_HOST = wochap-ssc.meta.address;
        OD_PORT = toString proxy.backendPort;
        OD_WEB_PORT = toString proxy.publicPort;
        OD_DATA_DIR = "/app/.od";
        # Nginx forwards the public hostname; the daemon checks Origin and Host.
        OD_ALLOWED_ORIGINS = "https://${proxy.subdomain}.${wochap-ssc.meta.domain}";
        HOME = "/home/open-design";
      };
      environmentFiles = lib.optional (ocfg.environmentFile != null) ocfg.environmentFile;
      # Host networking lets the daemon reach OmniRoute on 127.0.1.1:20128,
      # which its SSRF guard treats as loopback.
      extraOptions = [
        "--network=host"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs=/tmp:rw,nosuid,nodev,size=1g"
        "--tmpfs=/home/open-design:rw,nosuid,nodev,uid=${toString uid},gid=${toString gid},size=256m"
        "--pids-limit=512"
      ];
    };

    systemd.tmpfiles.rules = [ "d ${dataDir} 0700 ${toString uid} ${toString gid} -" ];

    # OmniRoute is reached through its always-on lazy socket, so no hard
    # dependency on podman-omniroute is needed.
    systemd.services.${serviceName}.serviceConfig = {
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = lib.mkForce 45;
      UMask = "0077";
      ProtectHome = true;
    };
  };
}
