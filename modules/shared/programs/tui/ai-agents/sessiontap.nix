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
  remote = cfg.sessionTap.remote;
  remoteEnabled = cfg.sessionTap.enableHub && remote.interfaces != [ ];
  withPort = host: "${host}:${toString remote.port}";
  # sops-nix places secrets at /run/secrets/<name> as regular files (owner
  # only), which satisfies SessionTap's private, non-symlink token check
  tokenSecret = sourceId: "local-sessiontap-hub-token-${sourceId}";
  tokenPath = sourceId: config.sops.secrets.${tokenSecret sourceId}.path;
  hubSourceIds = [ cfg.sessionTap.sourceId ] ++ cfg.sessionTap.hubSources;
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
    hubSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "sandbox" ];
      description = "Source IDs besides this host's own that the hub accepts; tokens come from local.yaml under local-sessiontap-hub-token-<sourceId>.";
    };
    remote = {
      name = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Hub display name shown in the pairing QR code and the companion app.";
      };
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "enp42s0"
          "tailscale0"
        ];
        description = "Interfaces whose firewall admits remote access. The hub binds the wildcard address, so the firewall is the only reachability limit. Empty disables remote access.";
      };
      advertise = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "gdesktop.tailnet.ts.net" ];
        description = "Extra hostnames added as endpoint hints to the pairing QR code.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8932;
        description = "Remote access TCP port.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sessionTap.enable) {
    assertions = [
      {
        assertion = config._custom.security.sops.enable;
        message = "sessionTap: hub tokens need _custom.security.sops.enable";
      }
    ];

    networking.firewall.interfaces = lib.mkIf remoteEnabled (
      lib.genAttrs remote.interfaces (_: {
        allowedTCPPorts = [ remote.port ];
      })
    );

    sops.secrets =
      lib.genAttrs
        (map tokenSecret (
          [ cfg.sessionTap.sourceId ] ++ lib.optionals cfg.sessionTap.enableHub cfg.sessionTap.hubSources
        ))
        (_: {
          sopsFile = ../../../../../secrets-sops/local.yaml;
          owner = config._custom.globals.userName;
        });

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
          token_file = "${tokenPath cfg.sessionTap.sourceId}"
          timeout_ms = 3000
          max_payload_bytes = 262144
        '';

        "sessiontap-hub/config.yaml" = lib.mkIf cfg.sessionTap.enableHub {
          text = ''
            version: 1
            listen: "0.0.0.0:8931"
            retention_days: 3
            subscriptions: []
            sources:
          ''
          + lib.concatMapStrings (
            id: "  ${builtins.toJSON id}: { token_file: ${builtins.toJSON (tokenPath id)} }\n"
          ) hubSourceIds
          + lib.optionalString remoteEnabled ''
            remote:
              name: ${builtins.toJSON remote.name}
              listen: ${builtins.toJSON [ (withPort "0.0.0.0") ]}
              advertise: ${builtins.toJSON (map withPort remote.advertise)}
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
