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
            # PERF: Home Manager enables this for primary accounts; it slows startup.
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
