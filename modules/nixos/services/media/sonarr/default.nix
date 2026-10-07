{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "sonarr";
  svc = cfg.services.sonarr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.sonarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 8989;
      environment = common.umaskEnv;
      volumes = [
        "${common.stateDir name}:/config:rw"
        (common.dataMount "torrents")
        (common.dataMount "media/series")
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=512"
      ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;
  };
}
