{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.email;
in
{
  # both sync methods (lieer for gmail, mbsync for everything else) feed the
  # same notmuch database, so enable it whenever any account is configured
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      programs.notmuch = {
        enable = true;

        search = {
          # hide trashed mails by default, like gmail does
          excludeTags = [
            "deleted"
            "spam"
            "trash"
          ];
        };
      };
    };
  };
}
