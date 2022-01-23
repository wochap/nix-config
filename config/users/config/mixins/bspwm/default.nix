{ config, pkgs, ... }:

let userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        bsp-layout
      ];

      etc = {
        "config/sxhkdrc" = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        "config/bspwmrc" = {
          source = ./dotfiles/bspwmrc;
          mode = "0755";
        };

        "scripts/lock.sh" = {
          source = ./scripts/lock.sh;
          mode = "0755";
        };

        "scripts/bspwm_borders.sh" = {
          source = ./scripts/bspwm_borders.sh;
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
          source =
            ./scripts/bspwm_subscribe_exclude_shadow_from_tiled_windows.sh;
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
        "scripts/bspwm_toggle_visibility.sh" = {
          source = ./scripts/bspwm_toggle_visibility.sh;
          mode = "0755";
        };
        "scripts/bspwm_open_or_focus.sh" = {
          source = ./scripts/bspwm_open_or_focus.sh;
          mode = "0755";
        };
        "scripts/bspwm_kitty_scratch.sh" = {
          source = ./scripts/bspwm_kitty_scratch.sh;
          mode = "0755";
        };
        "scripts/bspwm_center_window.sh" = {
          source = ./scripts/bspwm_center_window.sh;
          mode = "0755";
        };

        "scripts/projects/bspwm_dangerp.sh" = {
          source = ./scripts/bspwm_dangerp.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xsession = {
        enable = true;
        scriptPath = ".xsession-hm";
        initExtra = "";
        windowManager.bspwm = {
          enable = true;
          extraConfig = builtins.readFile ./dotfiles/bspwmrc;
        };
      };

      services.sxhkd = {
        enable = true;
        extraConfig = builtins.readFile ./dotfiles/sxhkdrc;
      };
    };
  };
}
