{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.wobook;
  push = cfg.statusPush;
  gatus = config._custom.services.gatus;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  # gatus key: <group>_<name>
  pushKey = "apps_wobook";

  # `wobook status` is a real round-trip over the daemon's unix socket; the
  # client has no read timeout, so cap it or a hung daemon blocks the run
  statusPushScript = pkgs.writeShellScript "wobook-status-push" ''
    if out=$(${lib.getExe' pkgs.coreutils "timeout"} 10 ${lib.getExe' hmConfig.programs.wobook.package "wobook"} status 2>&1 >/dev/null); then
      query="success=true"
    else
      error=$(printf '%s' "''${out:-wobook status failed}" | ${lib.getExe' pkgs.coreutils "head"} -c 200 | ${lib.getExe pkgs.jq} -sRr @uri)
      query="success=false&error=$error"
    fi
    exec ${lib.getExe pkgs.curl} -fsS --max-time 10 -X POST \
      -H "Authorization: Bearer $(${lib.getExe' pkgs.coreutils "cat"} ${
        config.sops.secrets.${push.tokenSecret.sopsKey}.path
      })" \
      "${push.gatusUrl}/api/v1/endpoints/${pushKey}/external?$query"
  '';
in
{
  # System firewall for sync (UDP 47390-47399) and mDNS (UDP 5353).
  imports = [ inputs.wobook.nixosModules.wobook ];

  options._custom.services.wobook = {
    enable = lib.mkEnableOption "wobook local-first bookmarks";
    chromiumExtensionIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Ids shown on chrome://extensions after "Load unpacked" of
        `nix build github:wochap/wobook#extension-chromium`. With browsers.enable, non-empty enables
        the Brave and Google Chrome native messaging hosts.
      '';
    };
    # headless always-online peer: relays changes between members that are
    # not online at the same time; sync port only open on tailscale0
    tailnetOnly = lib.mkEnableOption { };
    syncPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = if cfg.tailnetOnly then 47390 else null;
      description = ''
        `WOBOOK_SYNC_PORT` (47390-47399), keeps the endpoint peers remember
        stable. null picks the first free port once and persists it.
      '';
    };
    # a user timer runs `wobook status` and pushes the result to this host's
    # gatus (external endpoint with a heartbeat: no push means unhealthy)
    statusPush = {
      enable = lib.mkEnableOption { };
      gatusUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:${toString gatus.port}";
      };
      tokenSecret = {
        sopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "SOPS file with the bearer token gatus expects for the wobook external endpoint.";
        };
        sopsKey = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "server-gatus-wobook-token";
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      # Set unconditionally: openFirewall defaults to true in the upstream module.
      services.wobook.openFirewall = cfg.enable;
      services.wobook.firewallInterfaces = lib.mkIf cfg.tailnetOnly [ "tailscale0" ];

      # wobookd is a user service, keep it running without a login session
      users.users.${userName}.linger = lib.mkIf (cfg.enable && cfg.tailnetOnly) true;

      _custom.hm = lib.mkIf cfg.enable {
        imports = [ inputs.wobook.homeManagerModules.wobook ];

        programs.wobook = {
          enable = true;
          daemon.enable = true;
          fzf.enable = !cfg.tailnetOnly;
          deviceName = config.networking.hostName;
          hooks."pre-add.strip-utm" = "${inputs.wobook}/contrib/hooks/pre-add.strip-utm";
          browsers = lib.mkIf (!cfg.tailnetOnly) {
            firefox.enable = true;
            brave.enable = cfg.chromiumExtensionIds != [ ];
            googleChrome.enable = cfg.chromiumExtensionIds != [ ];
            inherit (cfg) chromiumExtensionIds;
          };
        };

        # Peers are dialed at their remembered tailnet IPs; multicast does not
        # cross the tailnet, so mDNS is useless here
        systemd.user.services.wobookd.Service.Environment =
          lib.optional (cfg.syncPort != null) "WOBOOK_SYNC_PORT=${toString cfg.syncPort}"
          ++ lib.optional cfg.tailnetOnly "WOBOOK_DISCOVERY=off";
      };
    }

    (lib.mkIf (cfg.enable && push.enable) {
      assertions = [
        {
          assertion = gatus.enable;
          message = "_custom.services.wobook.statusPush needs _custom.services.gatus on this host";
        }
        {
          assertion = push.tokenSecret.sopsFile != null;
          message = "_custom.services.wobook.statusPush needs tokenSecret.sopsFile";
        }
      ];

      # gatus reads it through its env file (root), the timer as the user
      sops.secrets.${push.tokenSecret.sopsKey} = {
        inherit (push.tokenSecret) sopsFile;
        owner = userName;
      };

      _custom.services.gatus = {
        secretEnv.GATUS_WOBOOK_TOKEN = push.tokenSecret.sopsKey;
        externalEndpoints = [
          {
            name = "wobook";
            group = "apps";
            token = "\${GATUS_WOBOOK_TOKEN}";
            # pushed every minute, tolerate a few missed runs
            heartbeat.interval = "5m";
          }
        ];
      };

      _custom.hm = {
        systemd.user.services.wobook-status-push = {
          Unit = {
            Description = "Push wobook daemon status to gatus";
            After = [ "wobookd.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${statusPushScript}";
          };
        };
        systemd.user.timers.wobook-status-push = {
          Unit.Description = "Push wobook daemon status to gatus every minute";
          Timer.OnCalendar = "minutely";
          Install.WantedBy = [ "timers.target" ];
        };
      };
    })
  ];
}
