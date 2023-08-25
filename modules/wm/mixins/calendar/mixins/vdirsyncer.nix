{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.calendar;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  # inherit (hmConfig.xdg) dataHome configHome;
  dataHome = "/home/gean/.local/share";
  configHome = "/home/gean/.config";
  vdirsyncer = "${pkgs.vdirsyncer}/bin/vdirsyncer";
  vdirsyncerScript = pkgs.writeShellScript "vdirsyncer" ''
    ${vdirsyncer} discover
    ${vdirsyncer} sync
    ${vdirsyncer} metasync
  '';
  passwordFetchCommand = passwordName:
    ''
      ["command", "${pkgs.coreutils}/bin/cat", "${configHome}/secrets/vdirsyncer/${passwordName}"]'';
in {

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.packages = [ pkgs.vdirsyncer ];

      systemd.user.services.vdirsyncer = {
        Unit.Description = "Synchronize Calendar and Contacts";
        Service = {
          Type = "oneshot";
          PassEnvironment = "PATH";
          ExecStart = "${vdirsyncerScript}";
        };
      };

      systemd.user.timers.vdirsyncer = {
        Unit.Description = "Synchronize Calendar and Contacts";
        Timer = {
          OnCalendar = "*:0/15"; # Every 15 minutes
          Unit = "vdirsyncer.service";
        };
        Install = { WantedBy = [ "timers.target" ]; };
      };

      xdg.configFile."vdirsyncer/config".text = let
        mkGoogleCalendarPair = { name }: ''
          [pair ${name}_google_calendar]
          a = "${name}_google_calendar_local"
          b = "${name}_google_calendar_remote"
          collections = ["from a", "from b"]
          conflict_resolution = "b wins"
          metadata = [ "displayname", "color" ]

          [storage ${name}_google_calendar_local]
          type = "filesystem"
          path = "${dataHome}/vdirsyncer/${name}-calendars/"
          fileext = ".ics"

          [storage ${name}_google_calendar_remote]
          type = "google_calendar"
          token_file = "${dataHome}/vdirsyncer/${name}_google_calendar_token_file"
          # vda (vdirsyncer_desktop_app) the name of the OAuth client
          client_id.fetch = ${passwordFetchCommand "vda_client_id"}
          client_secret.fetch = ${passwordFetchCommand "vda_client_secret"}
        '';
      in ''
        [general]
        # A folder where vdirsyncer can store some metadata about each pair.
        status_path = "${dataHome}/vdirsyncer/status/"

        ${mkGoogleCalendarPair { name = "personal"; }}
        ${mkGoogleCalendarPair { name = "work"; }}
      '';
    };
  };
}
