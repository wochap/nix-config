{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "prowlarr";
  svc = cfg.services.prowlarr;
  inherit (cfg.services) sonarr radarr lazylibrarian;
  # Container address of an app, or "" when it is disabled.
  appUrl =
    app: port:
    lib.optionalString cfg.services.${app}.enable "http://${common.containerName app}:${toString port}";
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.prowlarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 9696;
      environment = common.umaskEnv;
      environmentFiles = lib.optional common.declarative (common.apiKeyEnvFile name);
      volumes = [
        "${common.stateDir name}:/config:rw"
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=256"
      ];
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;

    sops.templates = lib.mkIf common.declarative (common.mkApiKeyEnv name "PROWLARR__AUTH__APIKEY");
    systemd.services = lib.mkMerge [
      { ${common.serviceName name} = common.mkSystemdService name { }; }
      (lib.mkIf common.declarative (
        common.mkConfigUnit name ./config.sh {
          env = {
            PROWLARR_URL = common.localUrl svc;
            PROWLARR_API_KEY_FILE = common.apiKeyFile name;
            PROWLARR_SELF_URL = "http://${common.containerName name}:9696";
            SONARR_URL = appUrl "sonarr" 8989;
            SONARR_API_KEY_FILE = lib.optionalString sonarr.enable (common.apiKeyFile "sonarr");
            RADARR_URL = appUrl "radarr" 7878;
            RADARR_API_KEY_FILE = lib.optionalString radarr.enable (common.apiKeyFile "radarr");
            LAZYLIBRARIAN_URL = appUrl "lazylibrarian" 5299;
            LAZYLIBRARIAN_API_KEY_FILE = lib.optionalString lazylibrarian.enable (
              common.apiKeyFile "lazylibrarian"
            );
          };
          # Apps added after their own bootstrap, so they already answer.
          after =
            lib.optional sonarr.enable "media-sonarr-config.service"
            ++ lib.optional radarr.enable "media-radarr-config.service";
        }
      ))
    ];
  };
}
