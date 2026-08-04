{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome;
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      # per-host calendar accounts (_custom.desktop.calendar.accounts)
      # mapped to home-manager calendar accounts with vdirsyncer and khal
      # enabled
      accounts.calendar = {
        basePath = "${dataHome}/vdirsyncer";
        accounts = lib.mapAttrs' (
          _: acc:
          lib.nameValuePair acc.name {
            # home-manager injects khal's default_calendar from the primary
            # account; only mark it primary once primaryCollection is set,
            # because with discover-type calendars khal expands collections
            # by their displayname and rejects the account name itself
            primary = acc.primary && acc.primaryCollection != null;
            inherit (acc) primaryCollection;

            local = {
              path = acc.localPath;
              type = "filesystem";
              fileExt = ".ics";
            };

            remote.type = "google_calendar";

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

            khal = {
              enable = true;
              type = "discover";
              inherit (acc)
                glob
                color
                readOnly
                ;
            };
          }
        ) cfg.accounts;
      };

      # generates ~/.config/vdirsyncer/config from the accounts above
      programs.vdirsyncer.enable = true;

      # vdirsyncer.service + timer running `vdirsyncer metasync` + `sync`
      services.vdirsyncer = {
        enable = true;
        frequency = cfg.frequency;
      };

      # merged into the home-manager generated units
      systemd.user.services.vdirsyncer = {
        Unit = {
          OnFailure = "vdirsyncer-on-failure.service";
          # regenerate the remind notifications from the synced ics files
          OnSuccess = "ics2rem.service";
        };
      };

      systemd.user.services.vdirsyncer-on-failure = {
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnotify}/bin/notify-send --app-name vdirsyncer --app-icon apport --icon apport --hint=int:transient:1 'Service failed'";
        };
      };

      # run once at boot/login if the last scheduled sync was missed
      systemd.user.timers.vdirsyncer.Timer.Persistent = true;
    };
  };
}
