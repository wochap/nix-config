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

                  # home-manager only conditions on .gmailieer.json, which
                  # already exists on a fresh setup, so the timer would kick
                  # off its own (unresumable) full sync in the background
                  # before the manual initial `gmi pull` has been done. Also
                  # require the state file, which only exists once that
                  # initial pull has completed.
                  ConditionPathExists = lib.mkForce [
                    "${maildir}/.gmailieer.json"
                    "${maildir}/.state.gmailieer.json"
                  ];
                };

                # home-manager's service runs `gmi sync`, which pushes *before*
                # it pulls. The push scans every local change since the notmuch
                # revision stored in .state.gmailieer.json (lastmod) and
                # fetches remote metadata for each one; when that revision is
                # stale/zero it walks the whole mailbox through the (heavily
                # rate limited) Gmail API, blocking the pull — and with it mail
                # delivery and mailnotify notifications — for hours.
                #
                # Run the fast, history-based pull first so new mail always
                # lands, then push local tag changes. Pulling first also
                # refreshes the historyId used by the push conflict check, so
                # lastmod advances reliably instead of getting stuck.
                Service = lib._custom.userServiceHardening // {
                  ExecCondition = "${networkCheck}";
                  ExecStart = lib.mkForce [
                    "${gmi} pull"
                    "${gmi} push"
                  ];
                  ProtectHome = "tmpfs";
                  BindPaths = [ maildir ];
                  RestrictAddressFamilies = [
                    "AF_INET"
                    "AF_INET6"
                    "AF_UNIX"
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
