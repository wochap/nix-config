{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.email;
  lieerNames = lib.attrNames (lib.filterAttrs (_: sync: sync == "lieer") cfg.accounts);
  mbsyncNames = lib.attrNames (lib.filterAttrs (_: sync: sync == "mbsync") cfg.accounts);
  # every sync unit that exists for the configured accounts
  syncUnits =
    (map (name: "lieer-${name}.service") lieerNames)
    ++ lib.optional (mbsyncNames != [ ]) "mbsync.service";
  # manual on-demand sync, e.g. `email-sync` or <F5> in neomutt
  email-sync = pkgs.writeScriptBin "email-sync" ''
    #!/usr/bin/env bash
    exec ${pkgs.systemd}/bin/systemctl --user start ${lib.concatStringsSep " " syncUnits} "$@"
  '';
in
{
  imports = [
    ./mixins/accounts
    ./mixins/lieer.nix
    ./mixins/mailcap
    ./mixins/mailnotify.nix
    ./mixins/mbsync.nix
    ./mixins/neomutt.nix
    ./mixins/notmuch.nix
    ./mixins/offlinemsmtp
  ];

  options._custom.desktop.email = {
    enable = lib.mkEnableOption { };
    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.enum [
          "lieer"
          "mbsync"
        ]
      );
      default = { };
      description = "Synchronization method per email account.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = lib.mkIf (syncUnits != [ ]) [ email-sync ];

      services.imapnotify = {
        enable = true;
        # go reimplementation of imapnotify (the nodejs one is unmaintained)
        package = pkgs.goimapnotify;
      };

      programs.msmtp.enable = true;
    };
  };
}
