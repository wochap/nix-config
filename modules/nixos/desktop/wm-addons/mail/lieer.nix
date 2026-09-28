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
  lieerAccounts = lib.filterAttrs (_: acc: acc.sync == "lieer") cfg.accounts;
  lieerNames = lib.attrNames lieerAccounts;
  gmi = "${hmConfig.programs.lieer.package}/bin/gmi";
  networkCheck = lib._custom.mkNetworkCheckScript "lieer-network-check" [ "oauth2.googleapis.com" ];

  # An unclean shutdown can truncate the state file mid-write. Restore it
  # from lieer's own .bak before gmi runs, instead of crashing on invalid
  # JSON every timer fire until someone notices and fixes it by hand.
  restoreStateScript =
    maildir:
    pkgs.writeShellScript "lieer-restore-state" ''
      state=${lib.escapeShellArg "${maildir}/.state.gmailieer.json"}
      backup="$state.bak"
      if [ -s "$state" ] && ${pkgs.jq}/bin/jq empty "$state" >/dev/null 2>&1; then
        exit 0
      fi
      if [ -s "$backup" ] && ${pkgs.jq}/bin/jq empty "$backup" >/dev/null 2>&1; then
        cp "$backup" "$state"
      fi
      exit 0
    '';
in
{
  config = lib.mkIf (cfg.enable && lieerNames != [ ]) {
    _custom.hm = {
      programs.lieer.enable = true;
      services.lieer.enable = true;

      systemd.user.services = lib.mkMerge [
        (lib.listToAttrs (
          map (
            name:
            let
              maildir = hmConfig.accounts.email.accounts.${name}.maildir.absPath;
            in
            {
              name = "lieer-${name}";
              value = {
                Unit = {
                  OnFailure = "lieer-on-failure.service";

                  # The first full pull must finish before timer-driven syncs.
                  ConditionPathExists = lib.mkForce [
                    "${maildir}/.gmailieer.json"
                    "${maildir}/.state.gmailieer.json"
                  ];
                };

                # A stale push can block delivery on Gmail's rate-limited API.
                Service = {
                  ExecCondition = "${networkCheck}";
                  ExecStartPre = "${restoreStateScript maildir}";
                  ExecStart = lib.mkForce [
                    "${gmi} pull"
                    "${gmi} push"
                  ];
                };
              };
            }
          ) lieerNames
        ))
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
