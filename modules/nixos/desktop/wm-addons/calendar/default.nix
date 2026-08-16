{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome;
in
{
  options._custom.desktop.calendar = {
    enable = lib.mkEnableOption { };

    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                defaultText = lib.literalExpression "name of the account attribute";
                description = "Account identifier used in generated paths and calendar configuration.";
              };

              primary = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Exactly one configured account must be primary.
                  `primaryCollection` is also required for khal's default.
                '';
              };

              primaryCollection = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Must match the synced collection display name in
                  `localPath/*/displayname`.
                '';
              };

              localPath = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}-calendars";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}-calendars";
                description = "Directory containing the synchronized calendar collections.";
              };

              tokenFile = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}_google_calendar_token_file";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}_google_calendar_token_file";
                description = "Path storing Google OAuth access and refresh tokens.";
              };

              remote = {
                type = lib.mkOption {
                  type = lib.types.enum [
                    "google_calendar"
                    "caldav"
                  ];
                  default = "google_calendar";
                  description = "Remote storage type for this calendar account.";
                };

                url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "CalDAV server URL; required for CalDAV accounts.";
                };

                userName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "User name for CalDAV authentication.";
                };

                passwordFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "File containing the CalDAV password.";
                };

                auth = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.enum [
                      "basic"
                      "digest"
                      "guess"
                    ]
                  );
                  default = null;
                  description = "CalDAV authentication method.";
                };

                verify = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Custom CA certificate used to verify the DAV server.";
                };

                verifyFingerprint = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Expected DAV server certificate fingerprint.";
                };
              };

              collections = lib.mkOption {
                type = lib.types.listOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                default = [
                  "from a"
                  "from b"
                ];
                description = "Collections to synchronize between the storages.";
              };

              conflictResolution = lib.mkOption {
                type = lib.types.enum [
                  "remote wins"
                  "local wins"
                ];
                default = "remote wins";
                description = ''
                  Concurrent edits on the losing side are overwritten.
                '';
              };

              metadata = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "displayname"
                  "color"
                ];
                description = "Metadata keys synchronized by `vdirsyncer metasync`.";
              };

              color = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "light green";
                description = "Color used by khal for this calendar.";
              };

              readOnly = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether khal must treat this calendar as read-only.";
              };

              glob = lib.mkOption {
                type = lib.types.str;
                default = "*";
                description = "Glob used by khal to discover local collections.";
              };
            };
          }
        )
      );
      default = { };
      description = "Calendar accounts synchronized by vdirsyncer and exposed to khal.";
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = "Systemd calendar expression controlling synchronization frequency.";
    };

    preAlert = lib.mkOption {
      type = lib.types.str;
      default = "+15";
      description = ''
        Remind tdelta passed to `ics2rem --posttime`; see `man remind`.
      '';
    };
  };

  imports = [
    ./remind
    ./khal.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          (cfg.accounts == { })
          || (lib.length (lib.filter (a: a.primary) (lib.attrValues cfg.accounts)) == 1);
        message = "Exactly one calendar account in _custom.desktop.calendar.accounts must be set as primary (primary = true;).";
      }
    ]
    ++ lib.mapAttrsToList (name: acc: {
      assertion =
        acc.remote.type != "caldav"
        || (acc.remote.url != null && acc.remote.userName != null && acc.remote.passwordFile != null);
      message = "Calendar account '${name}' uses `caldav` and must set remote.url, remote.userName, and remote.passwordFile.";
    }) cfg.accounts;
  };
}
