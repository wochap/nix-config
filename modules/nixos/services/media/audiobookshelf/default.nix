{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "audiobookshelf";
  svc = cfg.services.audiobookshelf;
  # The image defaults to port 80, which a non-root user cannot bind.
  port = 13378;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.audiobookshelf;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc port;
      environment = common.umaskEnv // {
        PORT = toString port;
        CONFIG_PATH = "/config";
        METADATA_PATH = "/metadata";
      };
      volumes = [
        "${common.stateDir name}/config:/config:rw"
        "${common.stateDir name}/metadata:/metadata:rw"
        # LazyLibrarian writes here; Audiobookshelf only reads and watches.
        (common.dataMountRo "media/audiobooks")
      ];
      extraOptions = common.hardening ++ [ "--pids-limit=512" ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };

    systemd.tmpfiles.rules = [
      (common.mkStateRule name)
      (common.mkStateRule "${name}/config")
      (common.mkStateRule "${name}/metadata")
    ];

    _custom.services.web-gate.proxies.${name} = common.mkProxy name svc;
  };
}
