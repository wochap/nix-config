{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome;
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ khal ];

      xdg.configFile."khal/config".text = # toml
        ''
          [calendars]

          [[personal_calendar_local]]
          path = ${dataHome}/vdirsyncer/personal-calendars/*
          type = discover

          [[boc_calendar_local]]
          path = ${dataHome}/vdirsyncer/boc-calendars/*
          type = discover

          [[se_calendar_local]]
          path = ${dataHome}/vdirsyncer/se-calendars/*
          type = discover

          [locale]
          timeformat = %H:%M
          dateformat = %a %d %b
          longdateformat = %a %d %b %Y
          datetimeformat = %a %d %b %H:%M
          longdatetimeformat = %a %d %b %Y %H:%M
          firstweekday = 0

          [default]
          highlight_event_days = True
          # enable_mouse = False

          [view]
          event_view_always_visible = True
        '';
    };
  };
}
