{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "jellyfin";
  svc = cfg.services.jellyfin;
  isVaapi = svc.hardwareAcceleration == "vaapi";
  isNvidia = svc.hardwareAcceleration == "nvidia";
  proxy = config._custom.services.web-proxies.${name} or { };
  # Clients learn this address from Jellyfin (discovery, Quick Connect), so
  # prefer the LAN hostname when the proxy is exposed.
  publishedUrl =
    if proxy.expose.enable or false then
      "https://${proxy.expose.host}"
    else
      "https://${name}.${common.domain}";
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.jellyfin;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 8096;
      environment = common.umaskEnv // {
        JELLYFIN_PublishedServerUrl = publishedUrl;
      };
      volumes = [
        "${common.stateDir name}/config:/config:rw"
        "${common.stateDir name}/cache:/cache:rw"
        (common.dataMountRo "media/movies")
        (common.dataMountRo "media/series")
      ];
      devices = lib.optionals isVaapi svc.vaapiDevices;
      extraOptions =
        common.hardening
        ++ [
          "--pids-limit=2048"
        ]
        # Numeric ids: group names resolve against the image's /etc/group.
        ++ lib.optionals isVaapi [
          "--group-add=${toString config.users.groups.video.gid}"
          "--group-add=${toString config.users.groups.render.gid}"
        ]
        ++ lib.optionals isNvidia [ "--device=nvidia.com/gpu=all" ];
    };

    hardware.nvidia-container-toolkit.enable = lib.mkIf isNvidia true;

    systemd.services.${common.serviceName name} = common.mkSystemdService name {
      extra = {
        wants = lib.optional isNvidia "nvidia-container-toolkit-cdi-generator.service";
        after = lib.optional isNvidia "nvidia-container-toolkit-cdi-generator.service";
      };
    };

    systemd.tmpfiles.rules = [
      (common.mkStateRule name)
      (common.mkStateRule "${name}/config")
      (common.mkStateRule "${name}/cache")
    ];

    _custom.services.web-proxies.${name} = common.mkProxy name svc;
  };
}
