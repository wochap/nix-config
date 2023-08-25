{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.calendar;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  # inherit (hmConfig.xdg) dataHome configHome;
  dataHome = "home/gean/.local/share";
  configHome = "home/gean/.config";
in {
  options._custom.wm.calendar = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      programs.vdirsyncer = {
        enable = true;
        statusPath = "${dataHome}/vdirsyncer/status/";
      };

      programs.khal = {
        enable = true;
        locale = {
          timeformat = "%H:%M";
          dateformat = "%Y-%m-%d";
          longdateformat = "%Y-%m-%d";
          datetimeformat = "%Y-%m-%d %H:%M";
          longdatetimeformat = "%Y-%m-%d %H:%M";
          firstweekday = 6;
        };
      };

      accounts.calendar.accounts.personal = {
        primary = true;
        primaryCollection = "a"; # TODO:

        khal = {
          enable = true;
          color = "dark red";
          type = "discover";
          glob = "*";
        };

        local = {
          fileExt = ".ics";
          path = "${dataHome}/vdirsyncer/personal-calendars";
          type = "filesystem";
        };

        remote = { type = "google_calendar"; };

        vdirsyncer = {
          enable = true;
          collections = [ "from a" "from b" ]; # TODO:
          conflictResolution = "remote wins";
          metadata = [ "displayname" "color" ];

          tokenFile =
            "${dataHome}/vdirsyncer/personal_google_calendar_token_file";
          clientIdCommand = [
            "${pkgs.coreutils}/bin/cat"
            "${configHome}/secrets/vdirsyncer/personal_client_id"
          ];
          clientSecretCommand = [
            "${pkgs.coreutils}/bin/cat"
            "${configHome}/secrets/vdirsyncer/personal_client_secret"
          ];
        };
      };
    };
  };
}

