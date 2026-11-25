{
  config,
  lib,
  pkgs,
  ...
}:

let
  traccarCfg = config._custom.services.traccar;
  cfg = traccarCfg.watchdog;

  secretSpecs = [
    {
      name = "traccarEmailSecret";
      spec = cfg.traccarEmailSecret;
    }
    {
      name = "traccarPasswordSecret";
      spec = cfg.traccarPasswordSecret;
    }
    {
      name = "telegramBotTokenSecret";
      spec = cfg.telegramBotTokenSecret;
    }
    {
      name = "telegramChatIdSecret";
      spec = cfg.telegramChatIdSecret;
    }
    {
      name = "webhookTokenSecret";
      spec = cfg.webhookTokenSecret;
    }
  ];

  allSecretsConfigured = builtins.all (s: s.spec.sopsFile != null) secretSpecs;

  mkSecretOption = defaultKey: desc: {
    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = cfg.sopsFile;
      defaultText = lib.literalExpression "config._custom.services.traccar.watchdog.sopsFile";
      description = "SOPS file holding ${desc}.";
    };
    sopsKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = defaultKey;
      description = "Key name inside the SOPS file for ${desc}.";
    };
  };
in
{
  options._custom.services.traccar.watchdog = {
    enable = lib.mkEnableOption "Traccar stationary watchdog daemon with Telegram alerts and webhooks";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8083;
      description = "Loopback HTTP port for watchdog webhook endpoints (/arm, /disarm, /toggle).";
    };

    deviceUniqueId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "999999999999999";
      description = "Fallback alias for defaultDevice (IMEI or uniqueId of the default Traccar device).";
    };

    defaultDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "GS900";
      description = "Default Traccar device name or uniqueId (IMEI) used when running /start, /status, /arm, or /disarm without a device argument.";
    };

    movementThresholdMeters = lib.mkOption {
      type = lib.types.ints.positive;
      default = 35;
      description = "Haversine distance threshold in meters from the parked anchor before alerting.";
    };

    ignitionGraceSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 15;
      description = "Grace period in seconds after ignition ON before alerting (allows Bluetooth /disarm webhook or transient speed jitter to cancel).";
    };

    alertOnIgnition = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to send Telegram alerts when attributes.ignition becomes true while armed.";
    };

    signalLossSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 120;
      description = "Duration in seconds of offline/unknown status, missing packets, or invalid GPS before alerting.";
    };

    alertCooldownSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Minimum seconds between repeated alerts of the same trigger type while armed.";
    };

    toggleDebounceSeconds = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 3;
      description = "Minimum seconds between consecutive /toggle actions for the same device (0 disables debouncing).";
    };

    autoBootstrapAdmin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically create the initial Traccar admin account via POST /api/users if login fails on a fresh DB.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = traccarCfg.dbPasswordSecret.sopsFile;
      defaultText = lib.literalExpression "config._custom.services.traccar.dbPasswordSecret.sopsFile";
      description = "Default SOPS file for traccar-watchdog secrets.";
    };

    traccarEmailSecret = mkSecretOption "server-traccar-admin-email" "the Traccar login email";
    traccarPasswordSecret = mkSecretOption "server-traccar-admin-password" "the Traccar login password";
    telegramBotTokenSecret = mkSecretOption "server-traccar-watchdog-telegram-bot-token" "the Telegram bot token";
    telegramChatIdSecret = mkSecretOption "server-traccar-watchdog-telegram-chat-id" "the authorized Telegram chat ID";
    webhookTokenSecret = mkSecretOption "server-traccar-watchdog-webhook-token" "the Bearer token for watchdog webhooks";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = traccarCfg.enable;
            message = "_custom.services.traccar.watchdog requires _custom.services.traccar.enable";
          }
        ]
        ++ map (s: {
          assertion = s.spec.sopsFile != null;
          message = "_custom.services.traccar.watchdog.${s.name}.sopsFile (or watchdog.sopsFile) must be set";
        }) secretSpecs;

        systemd.services.traccar-watchdog = {
          description = "Traccar Stationary Watchdog";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network-online.target"
            "traccar.service"
          ];
          wants = [
            "network-online.target"
            "traccar.service"
          ];
          environment = {
            TRACCAR_URL = "http://127.0.0.1:${toString traccarCfg.port}";
            WEBHOOK_HOST = "127.0.0.1";
            WEBHOOK_PORT = toString cfg.port;
            STATE_FILE = "/var/lib/traccar-watchdog/state.json";
            MOVEMENT_THRESHOLD_METERS = toString cfg.movementThresholdMeters;
            IGNITION_GRACE_SECONDS = toString cfg.ignitionGraceSeconds;
            ALERT_ON_IGNITION = lib.boolToString cfg.alertOnIgnition;
            SIGNAL_LOSS_SECONDS = toString cfg.signalLossSeconds;
            ALERT_COOLDOWN_SECONDS = toString cfg.alertCooldownSeconds;
            TOGGLE_DEBOUNCE_SECONDS = toString cfg.toggleDebounceSeconds;
            AUTO_BOOTSTRAP_ADMIN = lib.boolToString cfg.autoBootstrapAdmin;
            PYTHONUNBUFFERED = "1";
          }
          // lib.optionalAttrs (cfg.defaultDevice != null || cfg.deviceUniqueId != null) {
            TRACCAR_DEFAULT_DEVICE =
              if cfg.defaultDevice != null then cfg.defaultDevice else cfg.deviceUniqueId;
          }
          // lib.optionalAttrs (traccarCfg.computedAttributes != [ ]) {
            TRACCAR_COMPUTED_ATTRIBUTES_FILE = toString (
              pkgs.writeText "traccar-computed-attributes.json" (builtins.toJSON traccarCfg.computedAttributes)
            );
          };
          serviceConfig = {
            DynamicUser = true;
            StateDirectory = "traccar-watchdog";
            StateDirectoryMode = "0700";
            EnvironmentFile = lib.mkIf allSecretsConfigured config.sops.templates."traccar-watchdog.env".path;
            ExecStart = "${lib.getExe pkgs.python3} ${./traccar-watchdog.py}";
            Restart = "on-failure";
            RestartSec = 5;
            MemoryMax = "64M";
            UMask = "0077";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            LockPersonality = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            CapabilityBoundingSet = "";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
          };
        };
      }

      (lib.mkIf allSecretsConfigured {
        sops.secrets = builtins.listToAttrs (
          map (s: {
            name = s.spec.sopsKey;
            value = {
              inherit (s.spec) sopsFile;
            };
          }) secretSpecs
        );

        sops.templates."traccar-watchdog.env" = {
          mode = "0400";
          restartUnits = [ "traccar-watchdog.service" ];
          content = ''
            TRACCAR_EMAIL=${config.sops.placeholder.${cfg.traccarEmailSecret.sopsKey}}
            TRACCAR_PASSWORD=${config.sops.placeholder.${cfg.traccarPasswordSecret.sopsKey}}
            TELEGRAM_BOT_TOKEN=${config.sops.placeholder.${cfg.telegramBotTokenSecret.sopsKey}}
            TELEGRAM_CHAT_ID=${config.sops.placeholder.${cfg.telegramChatIdSecret.sopsKey}}
            WEBHOOK_TOKEN=${config.sops.placeholder.${cfg.webhookTokenSecret.sopsKey}}
          '';
        };
      })
    ]
  );
}
