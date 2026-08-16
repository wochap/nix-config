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
                  Unique identifier of the contacts account. becomes the
                  home-manager `accounts.contact.accounts.<name>` key, the
                  vdirsyncer pair `contacts_<name>`, and is used to build
                  the default local/token paths.
                '';
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
                  Collections to synchronize between the storages. null
                  syncs everything `vdirsyncer discover` finds. the
                  collection names (local subdirectories of `localPath`)
                  are also what khal uses for contact birthdays: until
                  this is set, `khalBirthdays` stays without effect.
                '';
              };

              localCollection = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = ''
                  Concrete local collection directory used by khal
                  birthdays. This is separate from `collections`, whose
                  `from a` and `from b` values are vdirsyncer discovery
                  directives, not collection names.
                '';
              };

              conflictResolution = lib.mkOption {
                type = lib.types.enum [
                  "remote wins"
                  "local wins"
                ];
                default = "remote wins";
                description = ''
                  Which side wins when the same contact was edited on both
                  sides since the last sync. same posture as the calendar
                  module.
                '';
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
                  description = ''
                    Type of the remote storage. `google_contacts` uses the
                    shared OAuth client credentials from the vdirsyncer
                    module; `carddav` additionally requires `remote.url`,
                    `remote.userName`, and `remote.passwordFile`.
                  '';
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
                  Show this account's contact birthdays in khal. requires
                  the calendar module's khal setup to be active; otherwise
                  this option is a no-op. Uses `localCollection`.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Contacts accounts, defined per host. they are mapped to
        home-manager's `accounts.contact.accounts` with vdirsyncer and
        khard enabled. hosts without accounts get no contacts stack.
      '';
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = ''
        How often to synchronize, systemd OnCalendar expression passed to
        `services.vdirsyncer.frequency`. The shared vdirsyncer module uses
        this only when no calendar accounts are active.
      '';
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
