{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  mbsyncAccounts = lib.filterAttrs (_: acc: acc.sync == "mbsync") cfg.accounts;
  mbsyncNames = lib.attrNames mbsyncAccounts;
  imapHosts = lib.unique (
    lib.filter (host: host != null) (
      map (name: hmConfig.accounts.email.accounts.${name}.imap.host) mbsyncNames
    )
  );
  networkCheck = lib._custom.mkNetworkCheckScript "mbsync-network-check" (
    if imapHosts != [ ] then imapHosts else [ "one.one.one.one" ]
  );
in
{
  config = lib.mkIf (cfg.enable && mbsyncAccounts != { }) {
    _custom.hm = {
      programs.mbsync.enable = true;

      services.mbsync = {
        enable = true;
        postExec = "${pkgs.notmuch}/bin/notmuch new";
      };

      systemd.user.services.mbsync.Service.ExecCondition = "${networkCheck}";

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
