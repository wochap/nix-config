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
      description = "Restrict neomutt's notmuch (lieer) folders to messages newer than this relative notmuch date (e.g. \"6months\", \"1y\"). null disables the restriction.";
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }: {
            options = {
              address = lib.mkOption { type = lib.types.str; };
              name = lib.mkOption { type = lib.types.str; };
              flavor = lib.mkOption {
                type = lib.types.str;
                default = "plain";
              };
              primary = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
              sync = lib.mkOption {
                type = lib.types.enum [
                  "lieer"
                  "mbsync"
                  "none"
                ];
                default = "none";
              };
              color = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
              pgpKey = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
              signatureLines = lib.mkOption {
                type = lib.types.listOf (lib.types.listOf lib.types.str);
                default = [ ];
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
              };
              inboxKey = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "If set, bind an index macro to this key that jumps to the account's inbox virtual folder.";
              };
              imapHost = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  IMAP server hostname, forwarded to the home-manager account
                  (used by mbsync and imapnotify). When null, the value already
                  provided by the account's flavor (e.g. imap.gmail.com) or set
                  directly on the home-manager account is kept. Set explicitly
                  to override.
                '';
              };
              smtpHost = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  SMTP server hostname, forwarded to the home-manager account
                  (used by msmtp, which offlinemsmtp wraps). When null, the
                  value already provided by the account's flavor (e.g.
                  smtp.gmail.com) or set directly on the home-manager account
                  is kept. Set explicitly to override.
                '';
              };
              virtualFolders = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      name = lib.mkOption {
                        type = lib.types.str;
                        description = "Name of the virtual folder, shown in neomutt's sidebar as <account>/<name>.";
                      };
                      query = lib.mkOption {
                        type = lib.types.str;
                        description = "Notmuch query for the virtual folder (e.g. \"from:*@github.com\"). Automatically restricted to this account's mail folder and to _custom.desktop.mail.querySince.";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Extra notmuch virtual folders for this account, shown in neomutt's sidebar.";
              };
              hooks = lib.mkOption {
                default = { };
                description = "Mail event hooks for this account, run from notmuch's post-new hook. Queries are scoped to this account's mail folder.";
                type = lib.types.submodule {
                  options = {
                    arrive = lib.mkOption {
                      default = [ ];
                      description = "Commands run when new mail arrives in this account. Each entry fires once per new message matching its `from` pattern, with the message id, From, Subject and Date as $1..$4 and the full message text on stdin.";
                      type = lib.types.listOf (
                        lib.types.submodule {
                          options = {
                            from = lib.mkOption {
                              type = lib.types.nonEmptyStr;
                              example = "*@github.com";
                              description = "Sender glob matched against new messages (notmuch `from:` prefix, e.g. \"*@github.com\").";
                            };
                            command = lib.mkOption {
                              type = lib.types.nonEmptyStr;
                              description = "Bash command to run. Use absolute paths for binaries (e.g. \${pkgs.libnotify}/bin/notify-send); runs in the environment of the sync unit that invoked notmuch new.";
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
