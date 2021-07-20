{ config, pkgs, ... }:

{
  config = {
    environment = {
      sessionVariables = {
        BSPWM_WINDOW_GAP = "25";
      };
      etc = {
        "config/sxhkdrc" = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        "config/bspwmrc" = {
          source = ./dotfiles/bspwmrc;
          mode = "0755";
        };

        "scripts/bspwm_external_rules.sh" = {
          source = ./scripts/bspwm_external_rules.sh;
          mode = "0755";
        };
        "scripts/bspwm_subscribe.sh" = {
          source = ./scripts/bspwm_subscribe.sh;
          mode = "0755";
        };
        "scripts/bspwm_subscribe_exclude_shadow_from_tiled_windows.sh" = {
          source = ./scripts/bspwm_subscribe_exclude_shadow_from_tiled_windows.sh;
          mode = "0755";
        };
        "scripts/bspwm_subscribe_polybar.sh" = {
          source = ./scripts/bspwm_subscribe_polybar.sh;
          mode = "0755";
        };
        "scripts/bspwm_autostart.sh" = {
          source = ./scripts/bspwm_autostart.sh;
          mode = "0755";
        };
        "scripts/bspwm_desktop_4.sh" = {
          source = ./scripts/bspwm_desktop_4.sh;
          mode = "0755";
        };
      };
    };
    services.xserver = {
      windowManager.bspwm = {
        enable = true;
        configFile = "/etc/config/bspwmrc";
        sxhkd.configFile = "/etc/config/sxhkdrc";
      };
      displayManager = {
        defaultSession = "none+bspwm";
      };
    };
  };
}
