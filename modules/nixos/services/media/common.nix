# Helpers shared by the media services. Imported as a plain function, not a
# NixOS module.
{
  config,
  lib,
  pkgs,
}:

let
  cfg = config._custom.services.media;
  inherit (pkgs._custom) wochap-ssc;
in
rec {
  inherit cfg;

  user = "${toString cfg.uid}:${toString cfg.gid}";

  # Container names double as DNS names on the shared network.
  containerName = name: "media-${name}";
  serviceName = name: "podman-${containerName name}";
  stateDir = name: "${cfg.stateDir}/${name}";

  # Published host port of a service, see mkServiceOptions in default.nix.
  webPort = svc: svc.port + 1;

  # Host path and in-container path share the same relative layout so every
  # service sees /data/torrents and /data/media/... at identical paths.
  dataMount = rel: "${cfg.dataRoot}/${rel}:/data/${rel}:rw";
  dataMountRo = rel: "${cfg.dataRoot}/${rel}:/data/${rel}:ro";

  hardening = [
    "--cap-drop=all"
    "--security-opt=no-new-privileges"
    "--tmpfs=/tmp:rw,nosuid,nodev,size=512m"
  ];

  # Capabilities an s6-overlay image (LinuxServer.io based) needs to switch
  # from root to PUID/PGID at start. Used only where no rootless image exists.
  s6Capabilities = {
    CHOWN = true;
    DAC_OVERRIDE = true;
    FOWNER = true;
    FSETID = true;
    SETGID = true;
    SETUID = true;
    KILL = true;
  };

  # Group-writable files so the desktop user (in group media) can edit them.
  umaskEnv = {
    UMASK = "002";
    TZ = if config.time.timeZone != null then config.time.timeZone else "UTC";
  };

  publish = svc: containerPort: [
    "${cfg.bindAddress}:${toString (webPort svc)}:${toString containerPort}"
  ];

  mkProxy =
    name: svc:
    lib.mkIf svc.proxy {
      enable = true;
      subdomain = name;
      serviceName = serviceName name;
      publicPort = svc.port;
      backendPort = webPort svc;
      lazy = false;
    };

  mkSystemdService =
    name:
    {
      timeoutStop ? 45,
      extra ? { },
    }:
    lib.mkMerge [
      {
        # Explicit ordering after multi-user.target drops the implicit
        # After= that WantedBy adds, so boot and login never wait on image
        # pulls. The stack still starts at boot on desktops and servers.
        after = [
          "multi-user.target"
          "media-data-dirs.service"
        ];
        requires = [ "media-data-dirs.service" ];
        # Stop retrying after repeated failures instead of looping forever.
        startLimitBurst = 5;
        startLimitIntervalSec = 300;
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = lib.mkForce timeoutStop;
          ProtectHome = true;
        };
      }
      extra
    ];

  mkStateRule = name: "d ${stateDir name} 0750 ${toString cfg.uid} ${toString cfg.gid} -";

  domain = wochap-ssc.meta.domain;
}
