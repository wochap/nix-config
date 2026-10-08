{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "radarr";
  svc = cfg.services.radarr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.radarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 7878;
      environment = common.umaskEnv;
      environmentFiles = lib.optional common.declarative (common.apiKeyEnvFile name);
      volumes = [
        "${common.stateDir name}:/config:rw"
        (common.dataMount "torrents")
        (common.dataMount "media/movies")
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=512"
      ];
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;

    sops.templates = lib.mkIf common.declarative (common.mkApiKeyEnv name "RADARR__AUTH__APIKEY");
    systemd.services = lib.mkMerge [
      { ${common.serviceName name} = common.mkSystemdService name { }; }
      (lib.mkIf common.declarative (
        common.mkConfigUnit name ../arr-config.sh {
          env = {
            ARR_NAME = "Radarr";
            ARR_URL = common.localUrl svc;
            ARR_API_KEY_FILE = common.apiKeyFile name;
            ARR_ROOT_FOLDER = "/data/media/movies";
            ARR_CATEGORY_FIELD = "movieCategory";
            ARR_CATEGORY = "movies";
            QBT_HOST = common.qbittorrentHost;
            QBT_PORT = "8080";
            QBT_KNOWN_HOSTS = "${common.containerName "qbittorrent"} ${common.containerName "vpn"}";
          };
        }
      ))
    ];
  };
}
