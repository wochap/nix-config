{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "bazarr";
  svc = cfg.services.bazarr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.bazarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 6767;
      environment = common.umaskEnv;
      volumes = [
        "${common.stateDir name}:/config:rw"
        (common.dataMount "media/movies")
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
