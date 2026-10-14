{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "lidarr";
  svc = cfg.services.lidarr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.lidarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 8686;
      environment = common.umaskEnv;
      environmentFiles = lib.optional common.declarative (common.apiKeyEnvFile name);
      volumes = [
        "${common.stateDir name}:/config:rw"
        (common.dataMount "torrents")
        # Soularr moves finished Soulseek downloads here and asks Lidarr to
        # import them.
        (common.dataMount "soulseek/downloads")
        (common.dataMount "media/music")
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=512"
      ];
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;

    sops.templates = lib.mkIf common.declarative (common.mkApiKeyEnv name "LIDARR__AUTH__APIKEY");
    systemd.services = lib.mkMerge [
      { ${common.serviceName name} = common.mkSystemdService name { }; }
      (lib.mkIf common.declarative (
        common.mkConfigUnit name ../arr-config.sh {
          env = {
            ARR_NAME = "Lidarr";
            ARR_URL = common.localUrl svc;
            ARR_API = "v1";
            ARR_API_KEY_FILE = common.apiKeyFile name;
            ARR_ROOT_FOLDER = "/data/media/music";
            ARR_ROOT_FOLDER_NAME = "Music";
            ARR_CATEGORY_FIELD = "musicCategory";
            ARR_CATEGORY = "music";
            QBT_HOST = common.qbittorrentHost;
            QBT_PORT = "8080";
            QBT_KNOWN_HOSTS = "${common.containerName "qbittorrent"} ${common.containerName "vpn"}";
          };
        }
      ))
    ];
  };
}
