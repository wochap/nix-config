{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.ai-agents;
  session-tap = inputs.session-tap.packages.${pkgs.stdenv.hostPlatform.system}.default;
  sessiontap-notify = pkgs.writeScriptBin "sessiontap-notify" (
    builtins.readFile ./scripts/sessiontap-notify.sh
  );
  sessiontap-notify-done = pkgs.writeScriptBin "sessiontap-notify-done" (
    builtins.readFile ./scripts/sessiontap-notify-done.sh
  );
in
{
  options._custom.programs.ai-agents.sessionTap = {
    enable = lib.mkEnableOption { };
    sourceId = lib.mkOption {
      type = lib.types.str;
      default = "host";
      description = "Stable source identifier sent to the SessionTap hub.";
    };
    sourceName = lib.mkOption {
      type = lib.types.str;
      default = "Host";
      description = "Human-readable SessionTap source name.";
    };
    hubUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8931/ingest";
      description = "SessionTap hub ingestion URL.";
    };
    trustedAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Non-loopback cleartext hub addresses trusted by sessiontapd.";
    };
    enableHub = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run the SessionTap hub for this user.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sessionTap.enable) {
    environment.systemPackages = [
      session-tap
      sessiontap-notify
      sessiontap-notify-done
    ];

    _custom.hm = {
      home.shellAliases = {
        cl = "sessiontap claude";
        cx = "sessiontap codex";
        qw = "sessiontap qwen";
        sp = "sessiontap pi";
      };

      xdg.configFile = {
        "sessiontap/config.toml".text = ''
          version = 1
          source_id = "${cfg.sessionTap.sourceId}"
          source_name = "${cfg.sessionTap.sourceName}"

          [sinks.hub]
          type = "hub"
          enabled = true
          url = "${cfg.sessionTap.hubUrl}"
          ${lib.optionalString (
            cfg.sessionTap.trustedAddresses != [ ]
          ) "trusted_addresses = ${builtins.toJSON cfg.sessionTap.trustedAddresses}"}
          timeout_ms = 3000
          max_payload_bytes = 262144
        '';

        "sessiontap-hub/config.yaml" = lib.mkIf cfg.sessionTap.enableHub {
          text = ''
            version: 1
            listen: "0.0.0.0:8931"
            retention_days: 3
            subscriptions: []
          '';
        };
      };

      systemd.user.services = {
        sessiontap-hub = lib.mkIf cfg.sessionTap.enableHub {
          Unit.Description = "SessionTap multi-source hub";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = "${session-tap}/bin/sessiontap-hub";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };

        sessiontap-notify = lib.mkIf cfg.sessionTap.enableHub {
          Unit = {
            Description = "SessionTap agent notifications";
            After = [ "sessiontap-hub.service" ];
            Wants = [ "sessiontap-hub.service" ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = "${sessiontap-notify}/bin/sessiontap-notify";
            Restart = "always";
            RestartSec = 2;
          };
        };

        sessiontapd = {
          Unit = {
            Description = "SessionTap broker daemon";
            After = lib.optionals cfg.sessionTap.enableHub [ "sessiontap-hub.service" ];
            Wants = lib.optionals cfg.sessionTap.enableHub [ "sessiontap-hub.service" ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = "${session-tap}/bin/sessiontapd";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      };
    };
  };
}
