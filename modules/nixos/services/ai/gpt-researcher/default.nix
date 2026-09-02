{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  apiProxy = config._custom.services.web-proxies.gpt-researcher-api;
  webProxy = config._custom.services.web-proxies.gpt-researcher;
in
{
  config = lib.mkIf (cfg.enable && cfg.enableGptResearcher) {
    _custom.services.web-proxies = {
      gpt-researcher = {
        enable = true;
        subdomain = "gpt-researcher";
        serviceName = "podman-gpt-researcher-web";
        publicPort = 20300;
        backendPort = 20301;
        lazy = true;
      };

      gpt-researcher-api = {
        enable = true;
        subdomain = "gpt-researcher-api";
        serviceName = "podman-gpt-researcher-api";
        publicPort = 20800;
        backendPort = 20801;
        lazy = true;
      };
    };

    virtualisation.oci-containers.containers = {
      gpt-researcher-api = {
        image = cfg.gptResearcherImage;
        user = "0:0";
        cmd = [
          "uvicorn"
          "main:app"
          "--host"
          wochap-ssc.meta.address
          "--port"
          (toString apiProxy.backendPort)
        ];
        volumes = [
          "/var/lib/gpt-researcher/my-docs:/usr/src/app/my-docs:rw"
          "/var/lib/gpt-researcher/outputs:/usr/src/app/outputs:rw"
          "/var/lib/gpt-researcher/logs:/usr/src/app/logs:rw"
        ];
        environment = {
          DOC_PATH = "/usr/src/app/my-docs";
          HOST = wochap-ssc.meta.address;
          LOGGING_LEVEL = "INFO";
          OUTPUT_PATH = "/usr/src/app/outputs";
          PORT = toString apiProxy.backendPort;
        };
        environmentFiles = lib.optional (
          cfg.gptResearcherEnvironmentFile != null
        ) cfg.gptResearcherEnvironmentFile;
        extraOptions = [
          "--network=host"
          "--cap-drop=all"
          "--security-opt=no-new-privileges"
          "--pids-limit=1024"
        ];
      };

      gpt-researcher-web = {
        image = cfg.gptResearcherWebImage;
        cmd = [
          "npm"
          "run"
          "dev"
          "--"
          "--hostname"
          wochap-ssc.meta.address
          "--port"
          (toString webProxy.backendPort)
        ];
        volumes = [ "/var/lib/gpt-researcher/outputs:/app/outputs:rw" ];
        environment = {
          HOSTNAME = wochap-ssc.meta.address;
          NEXT_PUBLIC_BACKEND_URL = "http://${wochap-ssc.meta.address}:${toString apiProxy.publicPort}";
          NEXT_PUBLIC_GPTR_API_URL = "https://${apiProxy.subdomain}.${wochap-ssc.meta.domain}";
          PORT = toString webProxy.backendPort;
        };
        extraOptions = [
          "--network=host"
          "--cap-drop=all"
          "--security-opt=no-new-privileges"
          "--pids-limit=512"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/gpt-researcher 0750 root root -"
      "d /var/lib/gpt-researcher/logs 0750 root root -"
      "d /var/lib/gpt-researcher/my-docs 0750 root root -"
      "d /var/lib/gpt-researcher/outputs 0750 root root -"
    ];

    systemd.services = {
      podman-gpt-researcher-api.serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 45;
        UMask = "0027";
        ProtectHome = true;
      };

      podman-gpt-researcher-web.serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 30;
        UMask = "0027";
        ProtectHome = true;
      };
    };
  };
}
