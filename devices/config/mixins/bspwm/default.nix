{ config, pkgs, ... }:

{
  config = {
    environment = {
      sessionVariables = {
        BSPWM_WINDOW_GAP = "25";
      };
      etc = {
        bspwmrc = {
          source = ./dotfiles/bspwmrc;
          mode = "0755";
        };
        "bspwm_external_rules.sh" = {
          source = ./scripts/bspwm_external_rules.sh;
          mode = "0755";
        };
        "bspwm_subscribe.sh" = {
          source = ./scripts/bspwm_subscribe.sh;
          mode = "0755";
        };
        "bspwm_subscribe_exclude_shadow_from_tiled_windows.sh" = {
          source = ./scripts/bspwm_subscribe_exclude_shadow_from_tiled_windows.sh;
          mode = "0755";
        };
        "bspwm_subscribe_polybar.sh" = {
          source = ./scripts/bspwm_subscribe_polybar.sh;
          mode = "0755";
        };
        "bspwm_autostart.sh" = {
          source = ./scripts/bspwm_autostart.sh;
          mode = "0755";
        };
        "bspwm_desktop_4.sh" = {
          source = ./scripts/bspwm_desktop_4.sh;
          mode = "0755";
        };

        sxhkdrc = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
      };
    };
    services.xserver = {
      windowManager.bspwm = {
        enable = true;
        configFile = "/etc/bspwmrc";
        sxhkd.configFile = "/etc/sxhkdrc";
      };
      displayManager = {
        defaultSession = "none+bspwm";
      };
    };
  };
}
