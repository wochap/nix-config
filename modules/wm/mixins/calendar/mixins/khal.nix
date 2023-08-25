{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.calendar;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  # inherit (hmConfig.xdg) dataHome configHome;
  dataHome = "/home/gean/.local/share";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      nixpkgs.overlays = [
        # Workaround from https://github.com/NixOS/nixpkgs/issues/205014
        (self: super: {
          khal =
            super.khal.overridePythonAttrs (attrs: rec { doCheck = false; });
        })
      ];

      home.packages = [ pkgs.khal ];

      xdg.configFile."khal/config".text = ''
        [calendars]

        [[personal_calendar_local]]
        path = ${dataHome}/vdirsyncer/personal-calendars/*
        type = discover

        [[work_calendar_local]]
        path = ${dataHome}/vdirsyncer/work-calendars/*
        type = discover

        [locale]
        timeformat = %H:%M
        dateformat = %Y-%m-%d
        longdateformat = %Y-%m-%d
        datetimeformat = %Y-%m-%d %H:%M
        longdatetimeformat = %Y-%m-%d %H:%M
        firstweekday = 6
      '';
    };
  };
}
