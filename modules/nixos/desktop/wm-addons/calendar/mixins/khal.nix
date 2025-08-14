{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) userName preferDark;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) dataHome;

  mkThemeKhal = theme: # toml
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
      # PERF: highlight_event_days slows start up
      highlight_event_days = False
      # enable_mouse = False

      [view]
      event_view_always_visible = True
      theme = ${theme}
    '';
  catppuccin-khal-light-theme = mkThemeKhal "light";
  catppuccin-khal-dark-theme = mkThemeKhal "dark";
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ khal ];

      xdg.configFile = {
        "khal/config" = {
          text = if preferDark then
            catppuccin-khal-dark-theme
          else
            catppuccin-khal-light-theme;
          force = true;
        };
        "khal/config-light".text = catppuccin-khal-light-theme;
        "khal/config-dark".text = catppuccin-khal-dark-theme;
      };
    };
  };
}
