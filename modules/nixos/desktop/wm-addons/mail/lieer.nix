{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  lieerAccounts = lib.filterAttrs (_: acc: acc.sync == "lieer") cfg.accounts;
  lieerNames = lib.attrNames lieerAccounts;
in
{
  config = lib.mkIf (cfg.enable && lieerNames != [ ]) {
    _custom.hm = {
      programs.lieer.enable = true;
      services.lieer.enable = true;

      systemd.user.services = lib.mkMerge [
        (lib.genAttrs (map (name: "lieer-${name}") lieerNames) (_: {
          Unit.OnFailure = "lieer-on-failure.service";
        }))
        {
          lieer-on-failure = {
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.libnotify}/bin/notify-send --app-name lieer --app-icon apport --icon apport --hint=int:transient:1 'Service failed'";
            };
          };
        }
      ];

      accounts.email.accounts = lib.mapAttrs (name: acc: {
        lieer = {
          enable = true;
          sync.enable = true;
          settings = {
            ignore_empty_history = true;
          };
        };

        folders = {
          drafts = "Drafts";
          sent = null;
          trash = "Trash";
        };
      }) lieerAccounts;
    };
  };
}
