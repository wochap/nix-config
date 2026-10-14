{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "navidrome";
  svc = cfg.services.navidrome;
  port = 4533;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.navidrome;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc port;
      environment = common.umaskEnv // {
        ND_PORT = toString port;
        # The image defaults to /data and /music; /data is the shared media
        # tree here, so state moves to /config.
        ND_DATAFOLDER = "/config";
        ND_CONFIGFILE = "/config/navidrome.toml";
        ND_MUSICFOLDER = "/data/media/music";
        # Lidarr imports into the library; the watcher picks new albums up,
        # the hourly scan catches what it misses.
        ND_SCANNER_SCHEDULE = "@every 1h";
      };
      volumes = [
        "${common.stateDir name}:/config:rw"
        # Lidarr writes here; Navidrome only reads.
        (common.dataMountRo "media/music")
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=512"
      ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;
  };
}
