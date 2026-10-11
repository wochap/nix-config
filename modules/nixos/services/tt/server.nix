{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.tt;
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  subdomain = "tt";
  inherit (cfg.server) peer tailnetOnly;
  # user unit StateDirectory= lives under $XDG_STATE_HOME, the system unit's
  # under /var/lib; server.key and admin.sock live next to the database
  db =
    if tailnetOnly then
      "/var/lib/tt-server/server.db"
    else
      "${hmConfig.xdg.stateHome}/tt-server/server.db";
  # Caddy (tailnetOnly) or nginx (web-gate) terminates TLS on this host
  backendAddress = if tailnetOnly then "127.0.0.1" else wochap-ssc.meta.address;
  serveArgs = [
    "--insecure-http"
    "--behind-proxy"
    "--listen ${backendAddress}:${toString cfg.server.backendPort}"
    "--web-dir ${cfg.webPackage}"
  ]
  ++ lib.optional (cfg.server.publicUrl != null) "--public-url ${cfg.server.publicUrl}"
  ++ lib.optionals peer.enable (
    [ "--peer-listen ${peer.listenAddress}:${toString peer.port}" ]
    ++ map (seed: "--peer ${seed}") peer.seeds
    ++ map (addr: "--peer-advertise ${addr}") peer.advertise
  );
in
{
  options._custom.services.tt.server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run `tt-server` (sync + web app) at https://tt.<domain>. It is never
        initialized automatically: until a one-time `tt-server init --name
        <host>` (first server) or `tt-server peer join <code>` (any other
        member) it serves in limited mode (health only, login/sync 503).
        Both work while it runs; `TT_SERVER_DB` points them at the database.
      '';
    };
    tailnetOnly = lib.mkEnableOption ''
      mode for a headless public host: a system service (no lingering, no
      web-gate), the web app and client API at https://<tailnetDomain>
      through Caddy for tailnet addresses only, and the peer port only open
      on tailscale0. An always-online member also relays changes between
      members that are not online at the same time
    '';
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tt.vps.example.com";
      description = ''
        tailnetOnly: Caddy vhost for the web app and client API, with a Let's
        Encrypt certificate from the Cloudflare DNS-01 challenge, so it needs
        no public record or open port. Tailnet clients resolve it to the
        tailnet IP (e.g. a headscale `dns.extra_records` entry); anyone else
        reaching Caddy is refused by source address.
      '';
    };
    cloudflareTokenSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "tailnetOnly: SOPS file with a Cloudflare API token (Zone DNS Edit, Zone Read) for the DNS-01 challenge.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-cloudflare-dns-api-token";
      };
    };
    publicPort = lib.mkOption {
      type = lib.types.port;
      default = 8770;
    };
    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 8771;
    };
    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if tailnetOnly then
          lib.mapNullable (domain: "https://${domain}") cfg.server.tailnetDomain
        else
          "https://${subdomain}.${wochap-ssc.meta.domain}";
      defaultText = lib.literalExpression ''"https://tt.''${pkgs._custom.wochap-ssc.meta.domain}", or "https://<tailnetDomain>" with tailnetOnly'';
      description = ''
        `--public-url`: this server's client URL as browsers reach it. Told to
        members so a web app installed from any of them can fail over here,
        and its origin is allowed by CORS on every member.
      '';
    };
    peer = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Accept links from member servers on a dedicated mutual-TLS port
          (`--peer-listen`, not behind nginx) and open it in the firewall.
          Pair once with `tt-server peer invite` here and `tt-server peer
          join <code>` on the other host.
        '';
      };
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8772;
      };
      seeds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "glegion.tail1234.ts.net:8772" ];
        description = "`--peer` host:port of members to dial before any link told us their addresses.";
      };
      advertise = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "gdesktop.tail1234.ts.net:8772" ];
        description = "`--peer-advertise` host:port at which members reach this peer port, tried before interface addresses.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.server.enable) (
    lib.mkMerge [
      {
        # `tt-server user add|peer …` work without --db
        _custom.hm.home.sessionVariables.TT_SERVER_DB = db;
      }

      (lib.mkIf (!tailnetOnly) {
        # Not lazy: the daemon keeps a sync websocket open all the time
        _custom.services.web-gate.proxies.tt = {
          enable = true;
          inherit subdomain;
          inherit (cfg.server) publicPort backendPort;
          lazy = false;
          serviceScope = "user";
          inherit userName;
        };

        # Non-members fail the TLS handshake; pairing needs the invite secret
        networking.firewall.allowedTCPPorts = lib.optional peer.enable peer.port;

        _custom.hm.systemd.user.services.tt-server = {
          Unit = {
            Description = "tt sync server + web app";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe' cfg.package "tt-server"} --db ${db} serve ${lib.concatStringsSep " " serveArgs}";
            StateDirectory = "tt-server";
            StateDirectoryMode = "0700";
            UMask = "0077";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install.WantedBy = [ "default.target" ];
        };
      })

      (lib.mkIf tailnetOnly {
        assertions = [
          {
            assertion = cfg.server.tailnetDomain != null;
            message = "_custom.services.tt.server.tailnetOnly needs tailnetDomain";
          }
          {
            assertion = cfg.server.cloudflareTokenSecret.sopsFile != null;
            message = "_custom.services.tt.server.tailnetOnly needs cloudflareTokenSecret.sopsFile";
          }
        ];

        sops.secrets = lib.optionalAttrs (cfg.server.cloudflareTokenSecret.sopsFile != null) {
          ${cfg.server.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.server.cloudflareTokenSecret.sopsFile;
        };

        security.acme = lib.optionalAttrs (cfg.server.tailnetDomain != null) {
          acceptTerms = true;
          certs.${cfg.server.tailnetDomain} = {
            dnsProvider = "cloudflare";
            # the local resolver may answer from cache
            dnsResolver = "1.1.1.1:53";
            group = config.services.caddy.group;
            reloadServices = [ "caddy.service" ];
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
              config.sops.secrets.${cfg.server.cloudflareTokenSecret.sopsKey}.path;
          };
        };

        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
          443
        ]
        ++ lib.optional peer.enable peer.port;

        # Caddy may also serve other sites on the public 443 (e.g. headscale):
        # drop anything that does not come over the tailnet
        # (optionalAttrs: the vhost name is evaluated even on hosts without
        # tailnetOnly)
        services.caddy = {
          enable = true;
          virtualHosts = lib.optionalAttrs (cfg.server.tailnetDomain != null) {
            ${cfg.server.tailnetDomain} = {
              useACMEHost = cfg.server.tailnetDomain;
              extraConfig = ''
                @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
                abort @outside
                reverse_proxy 127.0.0.1:${toString cfg.server.backendPort}
              '';
            };
          };
        };

        # Runs as the user so `tt-server peer …` reaches db and admin.sock
        systemd.services.tt-server = {
          description = "tt sync server + web app";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe' cfg.package "tt-server"} --db ${db} serve ${lib.concatStringsSep " " serveArgs}";
            User = userName;
            Group = "users";
            StateDirectory = "tt-server";
            StateDirectoryMode = "0700";
            UMask = "0077";
            Restart = "on-failure";
            RestartSec = 2;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
          };
        };
      })
    ]
  );
}
