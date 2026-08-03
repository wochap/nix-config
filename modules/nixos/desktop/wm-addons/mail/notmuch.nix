{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  notmuchAccounts = lib.filterAttrs (_: acc: acc.sync == "lieer" || acc.sync == "mbsync") cfg.accounts;
in
{
  config = lib.mkIf (cfg.enable && notmuchAccounts != { }) {
    _custom.hm = {
      programs.notmuch = {
        enable = true;
        search = {
          excludeTags = [
            "deleted"
            "spam"
            "trash"
          ];
        };
      };

      accounts.email.accounts = lib.mapAttrs (name: acc: {
        notmuch.enable = true;
      }) notmuchAccounts;
    };
  };
}
