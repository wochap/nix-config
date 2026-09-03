{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (config._custom.globals) userName;
  inherit (pkgs._custom) wochap-ssc;
  omniroute-chat = pkgs.writeScriptBin "omniroute-chat" (builtins.readFile ./omniroute-chat.sh);
in
{
  options._custom.services.ai.enableOmniRoute = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    sops.secrets.local-omniroute-secret-key = lib.mkIf cfg.enableOmniRoute {
      sopsFile = ../../../../../secrets-sops/local.yaml;
      owner = userName;
    };

    environment.systemPackages = lib.optionals cfg.enableOmniRoute [ omniroute-chat ];

    _custom.services.web-proxies.omniroute = {
      enable = cfg.enableOmniRoute;
      subdomain = "omniroute";
      publicPort = 20128;
      backendPort = 20129;
      serviceName = "podman-omniroute";
      lazy = true;
    };

    virtualisation.oci-containers.containers.omniroute = lib.mkIf cfg.enableOmniRoute {
      image = "ghcr.io/diegosouzapw/omniroute:3.8.50@sha256:085c57adf499a8aaa9f35ccde95c0df9c11bd9ecd18d6c9edbf3b68b8079ba9d";
      volumes = [ "/var/lib/omniroute:/app/data" ];
      environment = {
        DATA_DIR = "/app/data";
        HOSTNAME = wochap-ssc.meta.address;
        PORT = toString config._custom.services.web-proxies.omniroute.backendPort;
        NEXT_PUBLIC_BASE_URL = "https://omniroute.${wochap-ssc.meta.domain}";
        OMNIROUTE_ALLOW_LOCAL_PROVIDER_URLS = "true";
        OMNIROUTE_ALLOW_PRIVATE_PROVIDER_URLS = "true";
      };
      extraOptions = [
        "--network=host"
        "--user=1000:1000"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs=/tmp:rw,nosuid,nodev,size=256m"
        "--pids-limit=512"
      ];
    };

    systemd.tmpfiles.rules = lib.optionals cfg.enableOmniRoute [
      "d /var/lib/omniroute 0700 1000 1000 -"
    ];

    systemd.services.podman-omniroute = lib.mkIf cfg.enableOmniRoute {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 45;
        UMask = "0077";
        ProtectHome = true;
      };
    };
  };
}
