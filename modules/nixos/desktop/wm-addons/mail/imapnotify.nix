{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  imapnotifyAccounts = lib.filterAttrs (
    _: acc: acc.sync == "lieer" || acc.sync == "mbsync"
  ) cfg.accounts;
in
{
  config = lib.mkIf (cfg.enable && imapnotifyAccounts != { }) {
    _custom.hm = {
      services.imapnotify = {
        enable = true;
        package = pkgs.goimapnotify;
      };

      accounts.email.accounts = lib.mapAttrs (name: acc: {
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify =
            if acc.sync == "lieer" then
              "${pkgs.systemd}/bin/systemctl --user start lieer-${name}.service &"
            else
              "${pkgs.isync}/bin/mbsync ${name}:%s && ${pkgs.notmuch}/bin/notmuch new";
        };
      }) imapnotifyAccounts;
    };
  };
}
