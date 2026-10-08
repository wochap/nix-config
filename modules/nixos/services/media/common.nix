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
          # tmpfiles only runs at boot or when its rules change, so a state
          # dir removed by hand would stay missing; recreate it before podman
          # bind-mounts it.
          ExecStartPre = [
            "${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=${cfg.stateDir}"
          ];
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = lib.mkForce timeoutStop;
          # No ProtectHome or other mount sandboxing here: it gives each
          # Exec* its own mount namespace, so the stop command cannot enter
          # the netns that podman run created ("netavark: setns: Invalid
          # argument") and the container's NAT rules leak. The container
          # itself never sees /home.
        };
      }
      extra
    ];

  mkStateRule = name: "d ${stateDir name} 0750 ${toString cfg.uid} ${toString cfg.gid} -";

  # Declarative layer, see README.md. Every bootstrap script runs as root on
  # the host and reaches the apps through their published loopback ports.
  declarative = cfg.declarative.enable;
  localUrl = svc: "http://${cfg.bindAddress}:${toString (webPort svc)}";
  # qBittorrent as the other containers see it.
  qbittorrentHost = containerName (
    if cfg.services.qbittorrent.vpn.enable then "vpn" else "qbittorrent"
  );
  apiKeyFile = name: config.sops.secrets.${cfg.declarative.apiKeys.${name}.sopsKey}.path;
  adminPasswordFile = config.sops.secrets.${cfg.declarative.admin.passwordSecret.sopsKey}.path;
  # Bookkeeping of the bootstrap units, never an app's own state.
  declarativeStateDir = "/var/lib/media-declarative";

  # URL users open for a service: the LAN host when web-gate exposes it,
  # else the .local name.
  publicUrl =
    name:
    let
      proxy = config._custom.services.web-gate.proxies.${name} or { };
    in
    if proxy.expose.enable or false then
      "https://${proxy.expose.host}"
    else
      "https://${name}.${domain}";

  # Env file handing a pinned API key to an app through its documented env
  # var: <APP>__AUTH__APIKEY for Servarr apps (overrides config.xml), API_KEY
  # for Seerr. Keeps the key out of the Nix store.
  mkApiKeyEnv = name: variable: {
    "media-${name}.env" = {
      mode = "0400";
      restartUnits = [ "${serviceName name}.service" ];
      content = ''
        ${variable}=${config.sops.placeholder.${cfg.declarative.apiKeys.${name}.sopsKey}}
      '';
    };
  };
  apiKeyEnvFile = name: config.sops.templates."media-${name}.env".path;

  # lib.sh plus one script, checked by shellcheck at build time.
  mkScript =
    scriptName: file:
    {
      env ? { },
      runtimeInputs ? [ ],
    }:
    pkgs.writeShellApplication {
      name = scriptName;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.gawk
        pkgs.jq
      ]
      ++ runtimeInputs;
      runtimeEnv = {
        LOG_TAG = scriptName;
        WAIT_TRIES = "60";
        WAIT_DELAY = "5";
        ADMIN_USER = cfg.declarative.admin.username;
        ADMIN_PASSWORD_FILE = adminPasswordFile;
      }
      // env;
      text = builtins.readFile ./lib.sh + builtins.readFile file;
      # runtimeEnv writes ADMIN_USER=<name> unquoted; a name such as "admin"
      # then reads to shellcheck like a command assignment.
      excludeShellChecks = [ "SC2209" ];
    };

  # media-<name>-config: runs once the container is up and again whenever it
  # restarts (PartOf). The script waits for the API itself.
  mkConfigUnit =
    name: file:
    {
      env ? { },
      runtimeInputs ? [ ],
      after ? [ ],
    }:
    {
      "media-${name}-config" = {
        description = "Configure ${containerName name} through its API";
        wantedBy = [ "multi-user.target" ];
        # Same reason as mkSystemdService: never hold up multi-user.target.
        after = [
          "multi-user.target"
          "${serviceName name}.service"
        ]
        ++ after;
        requires = [ "${serviceName name}.service" ];
        partOf = [ "${serviceName name}.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe (mkScript "media-${name}-config" file { inherit env runtimeInputs; });
          TimeoutStartSec = "10min";
          UMask = "0077";
          PrivateTmp = true;
          StateDirectory = baseNameOf declarativeStateDir;
        };
      };
    };

  domain = wochap-ssc.meta.domain;
}
