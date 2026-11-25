{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.traccar;
  hasDomain = cfg.tailnetDomain != null;
  hasDbSecret = cfg.dbPasswordSecret.sopsFile != null;
  hasCloudflareSecret = cfg.cloudflareTokenSecret.sopsFile != null;
in
{
  imports = [
    ./watchdog.nix
  ];

  options._custom.services.traccar = {
    enable = lib.mkEnableOption "Traccar GPS tracking server";

    tailnetOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Restrict Caddy reverse proxy to tailnet clients (100.64.0.0/10, fd7a:115c:a1e0::/48).";
    };

    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "traccar.gvps.geanmar.com";
      description = "Tailnet domain name for Traccar web/API behind Caddy with Cloudflare DNS-01 ACME TLS.";
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

    dbPasswordSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "../../secrets-sops/server.yaml";
        description = "SOPS file holding the Traccar PostgreSQL password.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-traccar-db-password";
        description = "Key name inside the SOPS file for the Traccar PostgreSQL password.";
      };
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "HTTP port for the Traccar web/API server.";
    };

    gt06Port = lib.mkOption {
      type = lib.types.port;
      default = 5023;
      description = "TCP port for incoming GT06 protocol tracker connections and GPRS commands (WanWay GS900).";
    };

    enableOsmand = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the OsmAnd HTTP protocol listener for mobile Traccar Client apps.";
    };

    osmandPort = lib.mkOption {
      type = lib.types.port;
      default = 5055;
      description = "HTTP port for the OsmAnd protocol listener (bound to 127.0.0.1 and routed via Caddy when tailnetDomain is set).";
    };

    trackerHardening = {
      enable = lib.mkEnableOption "iptables connection/rate limiting and idle timeout for the public GT06 tracker port";

      maxConnections = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5;
        description = "Maximum concurrent TCP connections allowed on gt06Port (global across all sources).";
      };

      rateLimit = lib.mkOption {
        type = lib.types.str;
        default = "10/minute";
        description = "iptables -m limit rate for new TCP connections to gt06Port.";
      };

      rateLimitBurst = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5;
        description = "iptables -m limit burst size for new TCP connections to gt06Port.";
      };

      idleTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Traccar gt06.timeout in seconds before closing idle/stale tracker connections.";
      };
    };

    jvmMaxHeap = lib.mkOption {
      type = lib.types.str;
      default = "256m";
      description = "Maximum JVM heap size (-Xmx) passed to Traccar via JAVA_TOOL_OPTIONS.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra settings merged into services.traccar.settings (all leaf values must be strings).";
    };

    computedAttributes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            description = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Unique description for the Traccar computed attribute (used as idempotent key).";
            };
            attribute = lib.mkOption {
              type = lib.types.nonEmptyStr;
              example = "ignition";
              description = "Target Traccar attribute name (e.g., ignition, power, valid).";
            };
            expression = lib.mkOption {
              type = lib.types.nonEmptyStr;
              example = "speed > 0";
              description = "JEXL expression evaluated by Traccar on incoming positions.";
            };
            type = lib.mkOption {
              type = lib.types.enum [
                "string"
                "number"
                "boolean"
              ];
              default = "boolean";
              description = "Computed attribute value type.";
            };
            priority = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Evaluation priority (< 0 runs early, >= 0 runs late).";
            };
            devices = lib.mkOption {
              type = lib.types.listOf lib.types.nonEmptyStr;
              default = [ ];
              example = [ "865190070191278" ];
              description = "Device names or uniqueIds (IMEIs) to attach this attribute to. Empty list attaches to all devices.";
            };
          };
        }
      );
      default = [ ];
      description = "Declarative Traccar computed attributes reconciled automatically by traccar-watchdog.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = hasDbSecret;
            message = "_custom.services.traccar requires dbPasswordSecret.sopsFile";
          }
          {
            assertion = !cfg.trackerHardening.enable || !config.networking.nftables.enable;
            message = "_custom.services.traccar.trackerHardening requires the iptables firewall backend (networking.nftables.enable = false)";
          }
          {
            assertion = cfg.computedAttributes == [ ] || cfg.watchdog.enable;
            message = "_custom.services.traccar.computedAttributes requires _custom.services.traccar.watchdog.enable = true";
          }
        ];

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "traccar" ];
          ensureUsers = [
            {
              name = "traccar";
              ensureDBOwnership = true;
            }
          ];
        };

        services.traccar = {
          enable = true;
          settings = lib.recursiveUpdate (
            {
              database = {
                driver = "org.postgresql.Driver";
                url = "jdbc:postgresql://127.0.0.1:${toString config.services.postgresql.settings.port}/traccar";
                user = "traccar";
                password = "$TRACCAR_DB_PASSWORD";
              };
              web = {
                address = if hasDomain then "127.0.0.1" else "0.0.0.0";
                port = toString cfg.port;
              }
              // lib.optionalAttrs hasDomain {
                url = "https://${cfg.tailnetDomain}";
              };
              protocols.enable = lib.concatStringsSep "," (
                [ "gt06" ] ++ lib.optional cfg.enableOsmand "osmand"
              );
              gt06 = {
                port = toString cfg.gt06Port;
              }
              // lib.optionalAttrs cfg.trackerHardening.enable {
                timeout = toString cfg.trackerHardening.idleTimeout;
              };
            }
            // lib.optionalAttrs cfg.enableOsmand {
              osmand = {
                address = if hasDomain then "127.0.0.1" else "0.0.0.0";
                port = toString cfg.osmandPort;
              };
            }
          ) cfg.settings;
        };

        systemd.services.traccar = {
          requires = [
            "postgresql.target"
            "postgresql-setup.service"
          ];
          after = [
            "postgresql.target"
            "postgresql-setup.service"
          ];
          environment.JAVA_TOOL_OPTIONS = "-Xmx${cfg.jvmMaxHeap} -XX:+UseSerialGC";
          serviceConfig.MemoryMax = "512M";
        };

        networking.firewall = {
          allowedTCPPorts =
            lib.optional (!cfg.trackerHardening.enable) cfg.gt06Port
            ++ lib.optional (cfg.enableOsmand && !hasDomain) cfg.osmandPort
            ++ lib.optional (!hasDomain) cfg.port
            ++ lib.optional (hasDomain && !cfg.tailnetOnly) 443;
          extraCommands = lib.mkIf cfg.trackerHardening.enable ''
            # Rate-limit and cap concurrent TCP connections to Traccar GT06 port
            ip46tables -A nixos-fw -p tcp --dport ${toString cfg.gt06Port} -m conntrack --ctstate NEW \
              -m connlimit --connlimit-above ${toString cfg.trackerHardening.maxConnections} --connlimit-mask 0 \
              -j DROP
            ip46tables -A nixos-fw -p tcp --dport ${toString cfg.gt06Port} -m conntrack --ctstate NEW \
              -m limit --limit ${cfg.trackerHardening.rateLimit} --limit-burst ${toString cfg.trackerHardening.rateLimitBurst} \
              -j nixos-fw-accept
          '';
          interfaces.tailscale0.allowedTCPPorts = lib.optional (hasDomain && cfg.tailnetOnly) 443;
        };
      }

      (lib.mkIf hasDbSecret {
        sops.secrets.${cfg.dbPasswordSecret.sopsKey}.sopsFile = cfg.dbPasswordSecret.sopsFile;

        sops.templates."traccar.env" = {
          mode = "0400";
          restartUnits = [
            "postgresql-setup.service"
            "traccar.service"
          ];
          content = ''
            TRACCAR_DB_PASSWORD=${config.sops.placeholder.${cfg.dbPasswordSecret.sopsKey}}
          '';
        };

        systemd.services.postgresql-setup = {
          serviceConfig.LoadCredential = [
            "traccar_db_password:${config.sops.secrets.${cfg.dbPasswordSecret.sopsKey}.path}"
          ];
          postStart = ''
            db_password="$(<"$CREDENTIALS_DIRECTORY/traccar_db_password")"
            db_password="''${db_password//\'/\'\'}"
            psql -v ON_ERROR_STOP=1 -tAc "ALTER ROLE \"traccar\" WITH PASSWORD '$db_password';"
          '';
        };

        services.traccar.environmentFile = config.sops.templates."traccar.env".path;
      })

      (lib.mkIf hasDomain {
        assertions = [
          {
            assertion = hasCloudflareSecret;
            message = "_custom.services.traccar.tailnetDomain needs cloudflareTokenSecret.sopsFile";
          }
        ];

        sops.secrets = lib.optionalAttrs hasCloudflareSecret {
          ${cfg.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.cloudflareTokenSecret.sopsFile;
        };

        security.acme = lib.optionalAttrs hasCloudflareSecret {
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
                handle @outside {
                  abort
                }
              ''}
              ${lib.optionalString cfg.watchdog.enable ''
                handle_path /watchdog/* {
                  reverse_proxy 127.0.0.1:${toString cfg.watchdog.port} {
                    header_up X-Real-IP {remote_host}
                  }
                }
              ''}
              ${lib.optionalString cfg.enableOsmand ''
                handle_path /osmand* {
                  reverse_proxy 127.0.0.1:${toString cfg.osmandPort} {
                    header_up X-Real-IP {remote_host}
                  }
                }
                @osmand_post {
                  method POST
                  path /
                }
                handle @osmand_post {
                  reverse_proxy 127.0.0.1:${toString cfg.osmandPort} {
                    header_up X-Real-IP {remote_host}
                  }
                }
                @osmand_query {
                  path /
                  query id=*
                }
                handle @osmand_query {
                  reverse_proxy 127.0.0.1:${toString cfg.osmandPort} {
                    header_up X-Real-IP {remote_host}
                  }
                }
              ''}
              handle {
                reverse_proxy 127.0.0.1:${toString cfg.port} {
                  header_up X-Real-IP {remote_host}
                }
              }
            '';
          };
        };
      })
    ]
  );
}
