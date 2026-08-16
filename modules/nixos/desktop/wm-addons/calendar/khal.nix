{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.calendar;
  inherit (config._custom.globals) preferDark;
in
{
  config = lib.mkIf (cfg.enable && cfg.accounts != { }) {
    _custom.hm = {
      # generates ~/.config/khal/config; the [[...]] calendar sections come
      # from accounts.calendar.accounts (see the shared vdirsyncer module).
      # `default_calendar` (used by `khal new`) is injected by home-manager
      # from the primary account's primaryCollection, once set.
      programs.khal = {
        enable = true;

        locale = {
          timeformat = "%H:%M";
          dateformat = "%a %d %b";
          longdateformat = "%a %d %b %Y";
          datetimeformat = "%a %d %b %H:%M";
          longdatetimeformat = "%a %d %b %Y %H:%M";
          firstweekday = 0;
        };

        settings = {
          default = {
            # PERF: highlight_event_days slows start up; overrides the
            # `true` home-manager sets when a primary account exists
            highlight_event_days = false;
            enable_mouse = true;
          };
          view = {
            event_view_always_visible = true;
            theme = if preferDark then "dark" else "light";
          };
        };
      };

      home.shellAliases.ktoday = "khal list now +1d";
    };
  };
}
