{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.gatus;
  services = config._custom.services;
  hasDomain = cfg.tailnetDomain != null;

  # checks for the _custom services enabled on this host, against their
  # loopback backends (tailnet-only vhosts may not resolve from the host)
  autoEndpoints =
    lib.optionals services.headscale.enable [
      {
        name = "headscale";
        group = "core";
        url = "https://${services.headscale.domain}/health";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 168h"
        ];
      }
    ]
    ++ lib.optionals services.adguardhome.enable [
      {
        name = "adguardhome-dns";
        group = "core";
        url = builtins.head services.adguardhome.bindHosts;
        dns = {
          query-name = "quad9.net";
          query-type = "A";
        };
        conditions = [ "[DNS_RCODE] == NOERROR" ];
      }
      {
        name = "adguardhome-web";
        group = "core";
        url = "http://127.0.0.1:${toString config.services.adguardhome.port}";
        conditions = [ "[STATUS] < 400" ];
      }
    ]
    ++ lib.optionals (services.syncthing.enable && services.syncthing.tailnetOnly) [
      {
        name = "syncthing";
        group = "apps";
        url = "http://127.0.0.1:8384/rest/noauth/health";
        conditions = [
          "[STATUS] == 200"
          "[BODY].status == OK"
        ];
      }
    ]
    ++ lib.optionals (services.tt.enable && services.tt.server.tailnetOnly) [
      {
        name = "tt-server";
        group = "apps";
        url = "http://127.0.0.1:${toString services.tt.server.backendPort}";
        conditions = [ "[STATUS] < 500" ];
      }
    ]
    ++ lib.optionals (services.tt.enable && services.tt.server.peer.enable) [
      {
        name = "tt-peer";
        group = "apps";
        url = "tcp://127.0.0.1:${toString services.tt.server.peer.port}";
        conditions = [ "[CONNECTED] == true" ];
      }
    ]
    ++ lib.optionals (services.wobook.enable && services.wobook.syncPort != null) [
      {
        name = "wobook";
        group = "apps";
        url = "tcp://127.0.0.1:${toString services.wobook.syncPort}";
        conditions = [ "[CONNECTED] == true" ];
      }
    ];
in
{
  options._custom.services.gatus = {
    enable = lib.mkEnableOption { };
    port = lib.mkOption {
      type = lib.types.port;
      # 8080 (the gatus default) is taken by headscale
      default = 8090;
    };
    # Caddy vhost with a Let's Encrypt cert from the Cloudflare DNS-01
    # challenge (no public record or open port); tailnet clients resolve it to
    # the tailnet IP (e.g. a headscale `dns.extra_records` entry). null: web UI
    # on http://<tailnet ip>:<port>
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "status.vps.example.com";
    };
    cloudflareTokenSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "SOPS file with a Cloudflare API token (Zone DNS Edit, Zone Read) for the DNS-01 challenge.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-cloudflare-dns-api-token";
      };
    };
    autoEndpoints = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Check the _custom services enabled on this host.";
    };
    endpoints = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      description = "Extra gatus endpoints, see https://github.com/TwiN/gatus#endpoints";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.gatus = {
          enable = true;
          settings = {
            web = {
              address = if hasDomain then "127.0.0.1" else "0.0.0.0";
              inherit (cfg) port;
            };
            # keeps uptime history across restarts (default is in-memory)
            storage = {
              type = "sqlite";
              path = "/var/lib/gatus/data.db";
            };
            endpoints = map (
              e:
              {
                interval = "1m";
              }
              // e
            ) (lib.optionals cfg.autoEndpoints autoEndpoints ++ cfg.endpoints);
          };
        };

        # icmp:// endpoints
        systemd.services.gatus.serviceConfig.AmbientCapabilities = [ "CAP_NET_RAW" ];

        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
          (if hasDomain then 443 else cfg.port)
        ];
      }

      (lib.mkIf hasDomain {
        assertions = [
          {
            assertion = cfg.cloudflareTokenSecret.sopsFile != null;
            message = "_custom.services.gatus.tailnetDomain needs cloudflareTokenSecret.sopsFile";
          }
        ];

        sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.cloudflareTokenSecret.sopsFile;

        security.acme = {
          acceptTerms = true;
          certs.${cfg.tailnetDomain} = {
            dnsProvider = "cloudflare";
            # the local resolver may answer from cache
            dnsResolver = "1.1.1.1:53";
            group = config.services.caddy.group;
            reloadServices = [ "caddy.service" ];
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
              config.sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.path;
          };
        };

        # Caddy may also serve other sites on the public 443 (e.g. headscale):
        # drop anything that does not come over the tailnet
        services.caddy = {
          enable = true;
          virtualHosts.${cfg.tailnetDomain} = {
            useACMEHost = cfg.tailnetDomain;
            extraConfig = ''
              @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
              abort @outside
              reverse_proxy 127.0.0.1:${toString cfg.port}
            '';
          };
        };
      })
    ]
  );
}
