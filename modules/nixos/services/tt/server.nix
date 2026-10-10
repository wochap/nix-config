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
  listen = "${wochap-ssc.meta.address}:${toString cfg.server.backendPort}";
  # user unit StateDirectory= lives under $XDG_STATE_HOME; server.key and
  # admin.sock live next to the database
  db = "${hmConfig.xdg.stateHome}/tt-server/server.db";
  inherit (cfg.server) peer;
  serveArgs = [
    # nginx terminates TLS on this host
    "--insecure-http"
    "--behind-proxy"
    "--listen ${listen}"
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
      default = "https://${subdomain}.${wochap-ssc.meta.domain}";
      defaultText = lib.literalExpression ''"https://tt.''${pkgs._custom.wochap-ssc.meta.domain}"'';
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

  config = lib.mkIf (cfg.enable && cfg.server.enable) {
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

    # `tt-server user add|peer …` work without --db
    _custom.hm.home.sessionVariables.TT_SERVER_DB = db;

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
  };
}
