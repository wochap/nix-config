{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.contacts;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome configHome;
in
{
  options._custom.desktop.contacts = {
    enable = lib.mkEnableOption "Contacts setup";

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
                description = "Account identifier used in generated paths and vdirsyncer configuration.";
              };

              localPath = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}-contacts";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}-contacts";
                description = "Directory holding the synced local contact collections.";
              };

              tokenFile = lib.mkOption {
                type = lib.types.str;
                default = "${dataHome}/vdirsyncer/${config.name}_google_contacts_token_file";
                defaultText = lib.literalExpression "\${dataHome}/vdirsyncer/\${name}_google_contacts_token_file";
                description = "File where the Google OAuth access/refresh tokens are stored.";
              };

              collections = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.listOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str))
                );
                default = [
                  "from a"
                  "from b"
                ];
                description = ''
                  `null` syncs everything found by `vdirsyncer discover`.
                  These values are not used for khal birthdays.
                '';
              };

              localCollection = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = ''
                  Concrete collection used for khal birthdays; discovery
                  directives such as `from a` are invalid here.
                '';
              };

              conflictResolution = lib.mkOption {
                type = lib.types.enum [
                  "remote wins"
                  "local wins"
                ];
                default = "remote wins";
                description = "Side retained when the same contact is changed locally and remotely.";
              };

              metadata = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "displayname" ];
                description = "Metadata keys synchronized by `vdirsyncer metasync`.";
              };

              remote = {
                type = lib.mkOption {
                  type = lib.types.enum [
                    "google_contacts"
                    "carddav"
                  ];
                  default = "google_contacts";
                  description = "CardDAV requires `url`, `userName`, and `passwordFile`.";
                };

                url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "URL of the CardDAV storage, required when `remote.type = \"carddav\"`.";
                };

                userName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "User name for CardDAV authentication.";
                };

                passwordFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "File containing the CardDAV password.";
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
                  description = "CardDAV authentication method.";
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

              khalBirthdays = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Requires an active calendar stack and uses `localCollection`.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = "Contact accounts synchronized by vdirsyncer and exposed to khard.";
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = "Sync timer schedule, used only when no calendar accounts are active.";
    };
  };

  imports = [
    ./khard.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: acc: {
      assertion =
        acc.remote.type != "carddav"
        || (acc.remote.url != null && acc.remote.userName != null && acc.remote.passwordFile != null);
      message = "Contacts account '${name}' uses `carddav` and must set remote.url, remote.userName, and remote.passwordFile.";
    }) cfg.accounts;

  };
}
