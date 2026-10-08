{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "calibre-web";
  svc = cfg.services.calibreWeb;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    # s6-overlay image: starts as root, drops to PUID/PGID. No --user; the
    # capability set is the minimum the init needs to switch user.
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.calibreWeb;
      networks = [ cfg.network.name ];
      ports = common.publish svc 8083;
      environment = common.umaskEnv // {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        NETWORK_SHARE_MODE = "false";
      };
      volumes = [
        "${common.stateDir name}:/config:rw"
        "${cfg.dataRoot}/media/books/library:/calibre-library:rw"
        "${cfg.dataRoot}/media/books/ingest:/cwa-book-ingest:rw"
      ];
      capabilities = common.s6Capabilities;
      extraOptions = common.hardening ++ [ "--pids-limit=1024" ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { timeoutStop = 60; };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;
  };
}
