{
  config,
  lib,
  pkgs,
  ...
}:

let
  systemConfig = config;
  cfg = config._custom.desktop.mail;
  inherit (config._custom.globals) userName;

  lieerNames = lib.attrNames (lib.filterAttrs (_: acc: acc.sync == "lieer") cfg.accounts);
  mbsyncNames = lib.attrNames (lib.filterAttrs (_: acc: acc.sync == "mbsync") cfg.accounts);
  syncUnits =
    (map (name: "lieer-${name}.service") lieerNames)
    ++ lib.optional (mbsyncNames != [ ]) "mbsync.service";
  email-sync = pkgs.writeScriptBin "email-sync" ''
    #!/usr/bin/env bash
    exec ${pkgs.systemd}/bin/systemctl --user start ${lib.concatStringsSep " " syncUnits} "$@"
  '';
in
{
  imports = [
    ./accounts.nix
    ./hooks.nix
    ./imapnotify.nix
    ./lieer.nix
    ./mailcap
    ./mailnotify.nix
    ./mbsync.nix
    ./neomutt.nix
    ./notmuch.nix
    ./offlinemsmtp
  ];

  options._custom.desktop.mail = {
    enable = lib.mkEnableOption "Mail setup";
    querySince = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "6months";
      description = "Relative notmuch date limiting neomutt folders; `null` disables the limit.";
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }: {
            options = {
              address = lib.mkOption {
                type = lib.types.str;
                description = "Email address for this account.";
              };
              name = lib.mkOption {
                type = lib.types.str;
                description = "Display name for this account.";
              };
              flavor = lib.mkOption {
                type = lib.types.str;
                default = "plain";
                description = "Home Manager email-provider flavor.";
              };
              primary = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether this is the primary mail account.";
              };
              sync = lib.mkOption {
                type = lib.types.enum [
                  "lieer"
                  "mbsync"
                  "none"
                ];
                default = "none";
                description = "Backend used to synchronize incoming mail.";
              };
              color = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Neomutt status color for this account; empty disables it.";
              };
              pgpKey = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "OpenPGP key used to sign mail; empty disables signing.";
              };
              signatureLines = lib.mkOption {
                type = lib.types.listOf (lib.types.listOf lib.types.str);
                default = [ ];
                description = "Rows of text used to build the account signature.";
              };
              passwordSecret.sopsFile = lib.mkOption {
                type = lib.types.path;
                description = "SOPS file containing the account password.";
              };
              passwordSecret.sopsKey = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "${name}-mail-password";
                description = "Key containing the account password in the SOPS file.";
              };
              passwordSecret.path = lib.mkOption {
                type = lib.types.str;
                internal = true;
                readOnly = true;
                default = systemConfig.sops.secrets.${config.passwordSecret.sopsKey}.path;
                description = "Resolved runtime path of the account password secret.";
              };
              inboxKey = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional neomutt key binding that opens this account's inbox.";
              };
              imapHost = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional IMAP hostname overriding the provider flavor's value.";
              };
              smtpHost = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional SMTP hostname overriding the provider flavor's value.";
              };
              virtualFolders = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      name = lib.mkOption {
                        type = lib.types.str;
                        description = "Virtual-folder name shown as `<account>/<name>`.";
                      };
                      query = lib.mkOption {
                        type = lib.types.str;
                        description = "Notmuch query, automatically scoped to this account and `querySince`.";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Additional notmuch virtual folders shown in neomutt.";
              };
              hooks = lib.mkOption {
                default = { };
                description = "Mail-event hooks scoped to this account's folder.";
                type = lib.types.submodule {
                  options = {
                    arrive = lib.mkOption {
                      default = [ ];
                      description = "Commands run once per newly arrived message matching their sender pattern.";
                      type = lib.types.listOf (
                        lib.types.submodule {
                          options = {
                            from = lib.mkOption {
                              type = lib.types.nonEmptyStr;
                              example = "*@github.com";
                              description = "Notmuch sender glob matched against new messages.";
                            };
                            command = lib.mkOption {
                              type = lib.types.nonEmptyStr;
                              description = "Bash command; executable paths must be absolute.";
                            };
                          };
                        }
                      );
                    };
                  };
                };
              };
            };
          }
        )
      );
      default = { };
      description = "Mail accounts configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.desktop.networking.userUnitsOnConnect = syncUnits;

    assertions = [
      {
        assertion =
          (cfg.accounts == { })
          || (lib.length (lib.filter (a: a.primary) (lib.attrValues cfg.accounts)) == 1);
        message = "Exactly one mail account in _custom.desktop.mail.accounts must be set as primary (primary = true;).";
      }
    ];

    sops.secrets = lib.mapAttrs' (
      _: acc:
      lib.nameValuePair acc.passwordSecret.sopsKey {
        owner = userName;
        sopsFile = acc.passwordSecret.sopsFile;
      }
    ) cfg.accounts;

    _custom.hm = {
      home.packages = lib.mkIf (syncUnits != [ ]) [ email-sync ];
      programs.msmtp.enable = true;
    };
  };
}
