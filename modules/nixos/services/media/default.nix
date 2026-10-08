{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.media;
  inherit (config._custom.globals) userName;

  # Netavark reads network definitions from /etc/containers/networks, the same
  # way the upstream podman module declares the default network.
  networkConfig = {
    name = cfg.network.name;
    id = builtins.hashString "sha256" cfg.network.name;
    driver = "bridge";
    network_interface = cfg.network.interface;
    subnets = [
      {
        subnet = cfg.network.subnet;
        gateway = cfg.network.gateway;
      }
    ];
    ipv6_enabled = false;
    internal = false;
    dns_enabled = true;
    ipam_options.driver = "host-local";
  };

  # Subdirectories below dataRoot. The same relative layout is mounted at
  # /data inside every container so imports are hardlinks or renames.
  dataSubdirs = [
    "torrents"
    "torrents/movies"
    "torrents/series"
    "torrents/books"
    "torrents/audiobooks"
    "media"
    "media/movies"
    "media/series"
    "media/books"
    "media/books/library"
    "media/books/ingest"
    "media/audiobooks"
  ];

  mkServiceOptions =
    {
      description,
      port,
      admin ? false,
    }:
    {
      enable = lib.mkEnableOption description;
      port = lib.mkOption {
        type = lib.types.port;
        default = port;
        description = ''
          Base port on bindAddress. The web UI is published on port + 1,
          matching the web-gate publicPort/backendPort convention.
        '';
      };
      proxy = lib.mkOption {
        type = lib.types.bool;
        default = !admin;
        description = ''
          Register a web-gate virtual host. Admin UIs default to false and
          stay reachable only on the published loopback port.
        '';
      };
    };

  # API keys the declarative layer uses. Sonarr, Radarr, Prowlarr and Seerr
  # take theirs from SOPS through a documented env var. LazyLibrarian has no
  # such route; its SOPS value is a copy of the key shown in its UI.
  apiKeyServices = [
    "sonarr"
    "radarr"
    "prowlarr"
    "seerr"
    "lazylibrarian"
  ];
in
{
  imports = [
    ./jellyfin
    ./seerr
    ./sonarr
    ./radarr
    ./prowlarr
    ./qbittorrent
    ./bazarr
    ./lazylibrarian
    ./calibre-web
    ./audiobookshelf
  ];

  options._custom.services.media = {
    enable = lib.mkEnableOption "self-hosted media stack";

    dataRoot = lib.mkOption {
      type = lib.types.str;
      example = "/mnt/storage/media-server";
      description = ''
        Host directory holding torrents/ and media/. Mounted at /data inside the
        containers. Downloads and libraries must share one filesystem so imports
        can hardlink.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/media-server";
      description = "Host directory holding one config/state subdirectory per service.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "UID of the media user every container runs as.";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "GID of the media group every container runs as.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = pkgs._custom.wochap-ssc.meta.address;
      description = "Host address the container ports are published on.";
    };

    network = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "media";
        description = "Podman network the containers share. Names resolve via DNS.";
      };
      interface = lib.mkOption {
        type = lib.types.str;
        default = "podman-media";
        description = "Bridge interface name (max 15 characters).";
      };
      subnet = lib.mkOption {
        type = lib.types.str;
        default = "10.90.0.0/24";
      };
      gateway = lib.mkOption {
        type = lib.types.str;
        default = "10.90.0.1";
      };
    };

    declarative = {
      enable = lib.mkEnableOption ''
        the declarative configuration layer: API keys and a shared admin
        login from SOPS, and one media-<name>-config unit per enabled service
        that wires it to the others through documented APIs. Only adds what is
        missing; see README.md
      '';
      apiKeys = lib.genAttrs apiKeyServices (name: {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "SOPS file containing the ${name} API key (see README.md, Secrets).";
        };
        sopsKey = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "media-${name}-api-key";
          description = "Key containing the ${name} API key in the SOPS file.";
        };
      });
      admin = {
        username = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "admin";
          description = ''
            Admin login set on every app that has none yet: Sonarr, Radarr,
            Prowlarr, qBittorrent, and the Jellyfin wizard (which Seerr signs
            in with).
          '';
        };
        passwordSecret.sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "SOPS file containing the admin password (see README.md, Secrets).";
        };
        passwordSecret.sopsKey = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "media-admin-password";
          description = "Key containing the admin password in the SOPS file.";
        };
      };
      seerr.qualityProfile = lib.mkOption {
        type = lib.types.str;
        default = "HD-1080p";
        description = ''
          Radarr/Sonarr quality profile Seerr requests with. Falls back to the
          first profile when no profile has this name.
        '';
      };
    };

    # Pinned images. Update tag and digest together; see each service README.
    images = {
      jellyfin = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/jellyfin/jellyfin:12.2@sha256:357724bf0ae27a672c7cbaa899db2d9abeb13dbd8657ccce750258a4c059d037";
      };
      seerr = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/seerr-team/seerr:v3.5.0@sha256:27602401178d54f1964442287b9f23f67a3fa2252645ee8065839ea1c3f69e45";
      };
      sonarr = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/home-operations/sonarr:4.0.20.3012@sha256:1f19eb5e0f421418c1a956bbe01310a0141423afe28bd9a4b1dcb8629ff2bce2";
      };
      radarr = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/home-operations/radarr:6.4.4.10685@sha256:be53998a2d39cfa3c3315b70c7509a6a1f2a10c3aee9337653efc9f4c970430e";
      };
      prowlarr = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/home-operations/prowlarr:2.6.5.5623@sha256:6152751c3ea2e7751564f5952173d5e83eed0e09f3fabd2cb6bdb58690c39e2f";
      };
      qbittorrent = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/home-operations/qbittorrent:5.2.4@sha256:9307627e03981d5473aa31175ea76ed56ea3752333ca49d601b6af45e281e7ba";
      };
      bazarr = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/home-operations/bazarr:1.6.2@sha256:17dc1cff22e99694ffbfb06555526cb47a66b362b4d6c982f06b557f7caae2bb";
      };
      lazylibrarian = lib.mkOption {
        type = lib.types.str;
        default = "lscr.io/linuxserver/lazylibrarian:version-369cc854@sha256:f2605cc0c91e4dcc746b9aab7ac5aee57aaa74022c3993cd66aef211a86bf499";
      };
      calibreWeb = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/crocodilestick/calibre-web-automated:v4.0.8@sha256:5e00373854247750cc3e4479b492ae09293ff5e06ed10177f226634d97888679";
      };
      audiobookshelf = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/advplyr/audiobookshelf:2.37.1@sha256:581d68b2a6fc7ebf58d81c878a9f387cbbc0d88ac9d37b298b9cee10168af85b";
      };
      gluetun = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/qmcgaw/gluetun:v3.41.3@sha256:fa19cc76b2af13d57a8d3dc3066f2ada061b1c761b8aecf989b3877c0486e027";
      };
    };

    services = {
      jellyfin =
        mkServiceOptions {
          description = "Jellyfin";
          port = 21000;
        }
        // {
          hardwareAcceleration = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "vaapi"
                "nvidia"
              ]
            );
            default = null;
            description = ''
              vaapi hands the render nodes in vaapiDevices to the container (AMD
              and Intel). nvidia uses the CDI device from nvidia-container-toolkit.
              Hardware transcoding must still be enabled in the Jellyfin dashboard.
            '';
          };
          vaapiDevices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "/dev/dri/renderD128" ];
            description = "Render nodes passed to the container when hardwareAcceleration is vaapi.";
          };
        };
      seerr = mkServiceOptions {
        description = "Seerr";
        port = 21010;
      };
      calibreWeb = mkServiceOptions {
        description = "Calibre-Web Automated";
        port = 21020;
      };
      audiobookshelf = mkServiceOptions {
        description = "Audiobookshelf";
        port = 21030;
      };
      sonarr = mkServiceOptions {
        description = "Sonarr";
        port = 21100;
        admin = true;
      };
      radarr = mkServiceOptions {
        description = "Radarr";
        port = 21110;
        admin = true;
      };
      prowlarr = mkServiceOptions {
        description = "Prowlarr";
        port = 21120;
        admin = true;
      };
      qbittorrent =
        mkServiceOptions {
          description = "qBittorrent";
          port = 21130;
          admin = true;
        }
        // {
          vpn = {
            enable = lib.mkEnableOption ''
              a gluetun sidecar. qBittorrent then shares the sidecar's network
              namespace and only sees the VPN tunnel
            '';
            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = {
                VPN_SERVICE_PROVIDER = "mullvad";
                VPN_TYPE = "wireguard";
                SERVER_COUNTRIES = "Netherlands";
              };
              description = "Non-secret gluetun settings. See https://github.com/qdm12/gluetun-wiki.";
            };
            sopsKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "local-media-vpn-env";
              description = ''
                Key in secrets-sops/local.yaml whose value is an env file with the
                secret gluetun settings (WIREGUARD_PRIVATE_KEY, WIREGUARD_ADDRESSES,
                OPENVPN_USER, ...). null disables the sops secret.
              '';
            };
            environmentFiles = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "Extra env files handed to gluetun, in addition to the sops secret.";
            };
            extraOptions = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra podman run options for the gluetun container.";
            };
          };
        };
      bazarr = mkServiceOptions {
        description = "Bazarr";
        port = 21140;
        admin = true;
      };
      lazylibrarian = mkServiceOptions {
        description = "LazyLibrarian";
        port = 21150;
        admin = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.oci-containers.backend == "podman";
        message = "_custom.services.media needs the podman oci-containers backend.";
      }
      {
        assertion = builtins.stringLength cfg.network.interface <= 15;
        message = "_custom.services.media.network.interface must be at most 15 characters.";
      }
    ];

    users.groups.media.gid = cfg.gid;
    users.users.media = {
      isSystemUser = true;
      uid = cfg.uid;
      group = "media";
      description = "Media stack service user";
    };
    # Lets the desktop user manage files the containers create (UMASK=002).
    users.users.${userName}.extraGroups = [ "media" ];

    environment.etc."containers/networks/${cfg.network.name}.json".source =
      (pkgs.formats.json { }).generate "${cfg.network.name}.json"
        networkConfig;

    # Containers reach aardvark-dns on the bridge gateway.
    networking.firewall = lib.mkIf (config.networking.firewall.backend != "firewalld") {
      interfaces.${cfg.network.interface}.allowedUDPPorts = [ 53 ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Raw values, read by the bootstrap units (root). The containers get the
    # keys through the env file templates in each service module.
    sops.secrets = lib.mkIf cfg.declarative.enable (
      lib.listToAttrs (
        map
          (
            secret:
            lib.nameValuePair secret.sopsKey {
              inherit (secret) sopsFile;
              mode = "0400";
            }
          )
          (
            [ cfg.declarative.admin.passwordSecret ]
            ++ map (name: cfg.declarative.apiKeys.${name}) (
              lib.filter (name: cfg.services.${name}.enable) apiKeyServices
            )
          )
      )
    );

    # dataRoot often lives on a separate (nofail) disk. tmpfiles runs before
    # such mounts and would create the tree on the root fs underneath them, so
    # create it once the mount is up. chown/chmod are best effort: filesystems
    # without unix permissions (ntfs3, exfat) take ownership from mount options.
    systemd.services.media-data-dirs = {
      description = "Create media stack data directories";
      unitConfig.RequiresMountsFor = [ cfg.dataRoot ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatMapStringsSep "\n" (
        d:
        let
          path = lib.escapeShellArg "${cfg.dataRoot}${lib.optionalString (d != "") "/${d}"}";
        in
        ''
          mkdir -p ${path}
          chown ${toString cfg.uid}:${toString cfg.gid} ${path} || true
          chmod 2775 ${path} || true
        ''
      ) ([ "" ] ++ dataSubdirs);
    };
  };
}
