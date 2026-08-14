{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.contacts;
  calendarCfg = config._custom.desktop.calendar;

  # frequency ownership (design D4): `services.vdirsyncer.frequency` is a
  # single value, two modules setting it conflict at evaluation. the
  # calendar module owns the shared vdirsyncer timer when it provides
  # accounts; its timer then syncs all configured pairs, contacts
  # included. only when the calendar stack is absent does this module set
  # the frequency from `_custom.desktop.contacts.frequency`.
  calendarActive = calendarCfg.enable && calendarCfg.accounts != { };

  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome;
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.desktop.networking.userUnitsOnConnect = [ "vdirsyncer.service" ];

    _custom.hm = {
      # per-host contacts accounts (_custom.desktop.contacts.accounts)
      # mapped to home-manager contact accounts with vdirsyncer enabled
      accounts.contact = {
        basePath = "${dataHome}/vdirsyncer";
        accounts = lib.mapAttrs' (
          _: acc:
          lib.nameValuePair acc.name {
            local = {
              path = acc.localPath;
              type = "filesystem";
              fileExt = ".vcf";
            };

            remote = {
              inherit (acc.remote) type;
            }
            // lib.optionalAttrs (acc.remote.type == "carddav") {
              inherit (acc.remote) url userName passwordCommand;
            };

            vdirsyncer = {
              enable = true;
              inherit (acc)
                collections
                conflictResolution
                metadata
                tokenFile
                clientIdCommand
                clientSecretCommand
                ;
            };
          }
        ) cfg.accounts;
      };

      # generates ~/.config/vdirsyncer/config from the accounts above
      # (merged with the calendar pairs when the calendar module is active)
      programs.vdirsyncer.enable = true;

      # shared vdirsyncer.service + timer running `vdirsyncer metasync` +
      # `sync` over all configured pairs
      services.vdirsyncer = {
        enable = true;
        frequency = lib.mkIf (!calendarActive) cfg.frequency;
      };

      # When calendars are active their module owns the shared service
      # customization. Contacts-only setups need the same offline guard.
      systemd.user.services.vdirsyncer.Service.ExecCondition =
        lib.mkIf (!calendarActive)
          "${lib._custom.mkNetworkCheckScript "vdirsyncer-network-check" [ "one.one.one.one" ]}";
    };
  };
}
