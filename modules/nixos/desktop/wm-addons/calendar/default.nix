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
          # `config` here is the account submodule config (shadows the
          # outer one, which is not needed inside)
          { name, config, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                defaultText = lib.literalExpression "name of the account attribute";
                description = ''
                  Unique identifier of the calendar account. becomes the
                  home-manager `accounts.calendar.accounts.<name>` key, the
                  vdirsyncer pair `calendar_<name>`, the khal calendar name,
                  and is used to build the default local/token paths.
                '';
              };

              primary = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Whether this is the primary account. exactly one account
                  must be primary. together with `primaryCollection` it
                  becomes khal's `default_calendar` (used by `khal new`).
                '';
              };

              primaryCollection = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Name of the primary collection of this account, as khal
                  displays it. because the local calendars are `discover`ed,
                  khal expands them into one calendar per collection named
                  after the collection's displayname (synced from google via
                  metasync), so this must be that displayname (check the
                  `displayname` files inside the collection subdirectories
                  of `localPath`). only when this is set does the primary
                  account
                  become khal's `default_calendar` (required by `khal new`).
                '';
              };

              localPath = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}-calendars";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}-calendars";
                description = "Directory holding the synced local calendar collections.";
              };

              tokenFile = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}_google_calendar_token_file";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}_google_calendar_token_file";
                description = "File where the Google OAuth access/refresh tokens are stored.";
              };

              remote = {
                type = lib.mkOption {
                  type = lib.types.enum [
                    "google_calendar"
                    "caldav"
                  ];
                  default = "google_calendar";
                  description = "Type of the remote calendar storage.";
                };

                url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "URL of the CalDAV storage, required for `caldav`.";
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
                  Which side wins when the same event was edited on both
                  sides since the last sync. with "remote wins" edits made
                  on google are safe, local khal edits to concurrently
                  changed events are overwritten.
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
                description = "Color in which khal displays events of this calendar.";
              };

              readOnly = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Keep khal from making any changes to this calendar.";
              };

              glob = lib.mkOption {
                type = lib.types.str;
                default = "*";
                description = "Glob khal uses to discover the collections inside `localPath`.";
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Calendar accounts, defined per host. they are mapped to
        home-manager's `accounts.calendar.accounts` with vdirsyncer and
        khal enabled. hosts without accounts get no calendar stack
        (vdirsyncer/khal/remind are not set up).
      '';
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = ''
        How often to synchronize, systemd OnCalendar expression passed to
        `services.vdirsyncer.frequency`.
      '';
    };

    preAlert = lib.mkOption {
      type = lib.types.str;
      default = "+15";
      description = ''
        remind tdelta passed to `ics2rem --posttime`: how long before an
        event a pre-alert notification is sent ("+15" = 15 minutes
        before). see `man remind` for the tdelta syntax.
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
