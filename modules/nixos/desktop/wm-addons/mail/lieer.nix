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

                  # The first full pull must finish before timer-driven syncs.
                  ConditionPathExists = lib.mkForce [
                    "${maildir}/.gmailieer.json"
                    "${maildir}/.state.gmailieer.json"
                  ];
                };

                # A stale push can block delivery on Gmail's rate-limited API.
                Service = {
                  ExecCondition = "${networkCheck}";
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
