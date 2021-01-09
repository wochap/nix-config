# Common configuration
{ config, pkgs, ... }:

let
  colors = {
    background = "#222";
    background-alt = "#444";
    foreground = "#dfdfdf";
    foreground-alt = "#555";
    primary = "#ffb52a";
    secondary = "#e60053";
    alert = "#bd2c40";
  };
in
{
  services.polybar = {
    enable = true;
    script = "polybar top &";
    config = {
      "bar/top" = {
        #monitor = "\${env:MONITOR:HDMI-1}";
        width = "100%";
        height = 40;
        radius = 6;
        fixed-center = false;

        modules-left = "bspwm";
        modules-right = "battery";
        tray-position = "right";
        dpi = 210;
      };
      "module/bspwm" = {
        type = "internal/bspwm";

        label-focused = "%index%";
        label-focused-background = "${colors.background-alt}";
        label-focused-underline = "${colors.primary}";
        label-focused-padding = 2;

        label-occupied = "%index%";
        label-occupied-padding = 2;

        label-urgent = "%index%!";
        label-urgent-background = "${colors.alert}";
        label-urgent-padding = 2;

        label-empty = "%index%";
        label-empty-foreground = "${colors.foreground-alt}";
        label-empty-padding = 2;
      };
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "ADP1";
        full-at = "98";

        format-charging = "<animation-charging> <label-charging>";
        format-charging-underline = "#ffb52a";

        format-discharging = "<animation-discharging> <label-discharging>";
        format-discharging-underline = "\${self.format-charging-underline}";

        format-full-prefix = " ";
        format-full-prefix-foreground = "${colors.foreground-alt}";
        format-full-underline = "\${self.format-charging-underline}";

        ramp-capacity-0 = "";
        ramp-capacity-1 = "";
        ramp-capacity-2 = "";
        ramp-capacity-foreground = "${colors.foreground-alt}";

        animation-charging-0 = "";
        animation-charging-1 = "";
        animation-charging-2 = "";
        animation-charging-foreground = "${colors.foreground-alt}";
        animation-charging-framerate = 750;

        animation-discharging-0 = "";
        animation-discharging-1 = "";
        animation-discharging-2 = "";
        animation-discharging-foreground = "${colors.foreground-alt}";
        animation-discharging-framerate = 750;
      };
    };
  };
}
