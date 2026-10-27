{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.bugsink;
  ociBackend = config.virtualisation.oci-containers.backend;
  serviceName = "${ociBackend}-bugsink";
  hasDomain = cfg.tailnetDomain != null;
in
{
  options._custom.services.bugsink = {
    enable = lib.mkEnableOption "Bugsink error tracking server";

    tailnetOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Restrict Caddy reverse proxy to tailnet clients (100.64.0.0/10, fd7a:115c:a1e0::/48).";
    };

    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "bugsink.gvps.geanmar.com";
      description = ''
        Tailnet domain name for Bugsink. When set, Caddy terminates TLS
        with an ACME certificate obtained via Cloudflare DNS-01 and reverse
        proxies to Bugsink on port `port`. Tailnet clients resolve the name
        to this host's tailnet IP (e.g. via headscale `dns.extra_records`).
      '';
    };

    cloudflareTokenSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "SOPS file with a Cloudflare API token (Zone DNS Edit, Zone Read) for DNS-01 challenge.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-cloudflare-dns-api-token";
        description = "SOPS secret key holding the Cloudflare token.";
      };
    };

    secretKeySecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "../../secrets-sops/server.yaml";
        description = "SOPS file holding the Bugsink SECRET_KEY.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-bugsink-secret-key";
        description = "Key name inside the SOPS file for Bugsink SECRET_KEY.";
      };
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8005;
      description = "Host loopback port Bugsink listens on (127.0.0.1:port).";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bugsink";
      description = "Host directory mounted at /data inside the container.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 14237;
      description = "UID the container runs as (upstream default: 14237). It must own dataDir.";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 14237;
      description = "GID the container runs as (upstream default: 14237).";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/bugsink/bugsink:2.6.2";
      description = "OCI image to pull and run when build.enable is false.";
    };

    build = {
      enable = lib.mkEnableOption "building the Bugsink image locally via _custom.services.local-oci-images";

      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "inputs.bugsink";
        description = "Source tree containing the Bugsink Dockerfile.";
      };

      tag = lib.mkOption {
        type = lib.types.str;
        default = "latest";
        description = "Tag for the locally built image.";
      };

      dockerfile = lib.mkOption {
        type = lib.types.str;
        default = "Dockerfile";
        description = "Dockerfile path relative to source.";
      };

      buildArgs = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Build arguments passed to docker/podman build.";
      };
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        SITE_TITLE = "My Bugsink";
      };
      description = "Extra environment variables passed to the container.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = lib.literalExpression "[ config.sops.templates.\"bugsink.env\".path ]";
      description = "Environment files containing secrets (e.g. SECRET_KEY, CREATE_SUPERUSER, DATABASE_URL).";
    };

    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags passed to the container runtime (docker/podman run).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        _custom.services.local-oci-images = lib.mkIf cfg.build.enable {
          bugsink = {
            inherit (cfg.build)
              source
              tag
              dockerfile
              buildArgs
              ;
          };
        };

        virtualisation.oci-containers.containers.bugsink = {
          inherit serviceName;
          image = lib.mkIf (!cfg.build.enable) cfg.image;
          ports = [ "127.0.0.1:${toString cfg.port}:${toString cfg.port}" ];
          volumes = [ "${cfg.dataDir}:/data:rw" ];
          environment =
            {
              PORT = toString cfg.port;
              TIME_ZONE = config.time.timeZone;
            }
            // lib.optionalAttrs hasDomain {
              BASE_URL = "https://${cfg.tailnetDomain}";
              BEHIND_HTTPS_PROXY = "true";
              USE_X_FORWARDED_HOST = "true";
              USE_X_REAL_IP = "true";
            }
            // cfg.environment;
          environmentFiles =
            lib.optional (cfg.secretKeySecret.sopsFile != null) config.sops.templates."bugsink.env".path
            ++ lib.optional (cfg.secretKeySecret.sopsFile == null) "${cfg.dataDir}/secret_key.env"
            ++ cfg.environmentFiles;
          extraOptions = [
            "--cap-drop=all"
            "--security-opt=no-new-privileges"
            "--tmpfs=/tmp:rw,nosuid,nodev,size=512m"
            "--pids-limit=1024"
          ] ++ cfg.extraOptions;
        };

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 ${toString cfg.uid} ${toString cfg.gid} -"
        ];

        systemd.services.${serviceName} = {
          path = [
            pkgs.openssl
            pkgs.coreutils
          ];
          preStart = lib.optionalString (cfg.secretKeySecret.sopsFile == null) ''
            if [ ! -f "${cfg.dataDir}/secret_key.env" ]; then
              mkdir -p "${cfg.dataDir}"
              SECRET_VAL="$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c 64)"
              echo "SECRET_KEY=''${SECRET_VAL}" > "${cfg.dataDir}/secret_key.env"
              chmod 0600 "${cfg.dataDir}/secret_key.env"
              chown ${toString cfg.uid}:${toString cfg.gid} "${cfg.dataDir}/secret_key.env"
            fi
          '';
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = 5;
            TimeoutStopSec = lib.mkForce 45;
          };
        };
      }

      (lib.mkIf (cfg.secretKeySecret.sopsFile != null) {
        sops.secrets.${cfg.secretKeySecret.sopsKey}.sopsFile = cfg.secretKeySecret.sopsFile;
        sops.templates."bugsink.env" = {
          mode = "0400";
          restartUnits = [ "${serviceName}.service" ];
          content = ''
            SECRET_KEY=${config.sops.placeholder.${cfg.secretKeySecret.sopsKey}}
          '';
        };
      })

      (lib.mkIf hasDomain {
        assertions = [
          {
            assertion = cfg.cloudflareTokenSecret.sopsFile != null;
            message = "_custom.services.bugsink.tailnetDomain needs cloudflareTokenSecret.sopsFile";
          }
        ];

        sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.cloudflareTokenSecret.sopsFile;

        security.acme = {
          acceptTerms = true;
          certs.${cfg.tailnetDomain} = {
            dnsProvider = "cloudflare";
            dnsResolver = "1.1.1.1:53";
            group = config.services.caddy.group;
            reloadServices = [ "caddy.service" ];
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
              config.sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.path;
          };
        };

        services.caddy = {
          enable = true;
          virtualHosts.${cfg.tailnetDomain} = {
            useACMEHost = cfg.tailnetDomain;
            extraConfig = ''
              ${lib.optionalString cfg.tailnetOnly ''
                @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
                abort @outside
              ''}
              reverse_proxy 127.0.0.1:${toString cfg.port} {
                header_up X-Real-IP {remote_host}
              }
            '';
          };
        };
      })
    ]
  );
}
