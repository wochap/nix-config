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
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.prowlarr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 9696;
      environment = common.umaskEnv;
      volumes = [
        "${common.stateDir name}:/config:rw"
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=256"
      ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;
  };
}
