{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "lazylibrarian";
  svc = cfg.services.lazylibrarian;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    # s6-overlay image: starts as root, drops to PUID/PGID. No --user; the
    # capability set is the minimum the init needs to switch user.
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.lazylibrarian;
      networks = [ cfg.network.name ];
      ports = common.publish svc 5299;
      environment = common.umaskEnv // {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
      };
      volumes = [
        "${common.stateDir name}:/config:rw"
        (common.dataMount "torrents")
        # Ebook destination: Calibre-Web Automated picks files up from here.
        (common.dataMount "media/books/ingest")
        # Audiobook destination: Audiobookshelf watches this folder.
        (common.dataMount "media/audiobooks")
      ];
      capabilities = common.s6Capabilities;
      extraOptions = common.hardening ++ [ "--pids-limit=512" ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;
  };
}
