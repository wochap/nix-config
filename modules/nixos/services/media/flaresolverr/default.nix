{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "flaresolverr";
  svc = cfg.services.flaresolverr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    # Stateless. Runs as the image's own user (home /app): undetected-chromedriver
    # patches /app/chromedriver at start, so neither --user nor --read-only.
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.flaresolverr;
      networks = [ cfg.network.name ];
      ports = common.publish svc 8191;
      environment = {
        LOG_LEVEL = "info";
        inherit (common.umaskEnv) TZ;
      };
      extraOptions = common.hardening ++ [
        # Chromium crashes on large pages with the 64m default.
        "--shm-size=1g"
        "--pids-limit=1024"
      ];
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name { };
  };
}
