{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  mbsyncAccounts = lib.filterAttrs (_: acc: acc.sync == "mbsync") cfg.accounts;
in
{
  config = lib.mkIf (cfg.enable && mbsyncAccounts != { }) {
    _custom.hm = {
      programs.mbsync.enable = true;

      accounts.email.accounts = lib.mapAttrs (name: acc: {
        mbsync = {
          enable = true;
          create = "both";
          remove = "both";
          expunge = "both";
        };
      }) mbsyncAccounts;
    };
  };
}
