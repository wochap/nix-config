{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "seerr";
  svc = cfg.services.seerr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.seerr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 5055;
      environment = common.umaskEnv // {
        PORT = "5055";
      };
      # Seerr talks to Jellyfin, Sonarr and Radarr over the shared network;
      # it needs no media mounts.
      volumes = [ "${common.stateDir name}:/app/config:rw" ];
      extraOptions = common.hardening ++ [ "--pids-limit=512" ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;
  };
}
