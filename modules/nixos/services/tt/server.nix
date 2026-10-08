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
  listen = "${wochap-ssc.meta.address}:${toString cfg.server.backendPort}";
  # user unit StateDirectory= lives under $XDG_STATE_HOME
  db = "${hmConfig.xdg.stateHome}/tt-server/server.db";
in
{
  options._custom.services.tt.server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run `tt-server` (sync + web app) at https://tt.<domain>.";
    };
    publicPort = lib.mkOption {
      type = lib.types.port;
      default = 8770;
    };
    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 8771;
    };
    localUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://${listen}";
      readOnly = true;
      description = ''
        Plain HTTP URL for `tt login` on this host. The tt client only trusts
        webpki roots, so it can not use the nginx vhost signed by the local CA.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.server.enable) {
    # Not lazy: the daemon keeps a sync websocket open all the time
    _custom.services.web-gate.proxies.tt = {
      enable = true;
      subdomain = "tt";
      inherit (cfg.server) publicPort backendPort;
      lazy = false;
      serviceScope = "user";
      inherit userName;
    };

    # `tt-server user add <name>` works without --db
    _custom.hm.home.sessionVariables.TT_SERVER_DB = db;

    _custom.hm.systemd.user.services.tt-server = {
      Unit = {
        Description = "tt sync server + web app";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        # nginx terminates TLS on this host
        ExecStart = "${lib.getExe' cfg.package "tt-server"} --db ${db} serve --insecure-http --behind-proxy --listen ${listen} --web-dir ${cfg.webPackage}";
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
