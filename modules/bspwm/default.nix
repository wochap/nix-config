{ config, pkgs, lib, ... }:

let
  cfg = config._custom.bspwm;
  theme = config._theme;
  userName = config._userName;
in {
  options._custom.bspwm = { enable = lib.mkEnableOption "activate BSPWM"; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ bsp-layout ];

      etc = {
        "libinput-gestures.conf".text = ''
          gesture swipe left 3 bspc desktop -f next.local
          gesture swipe right 3 bspc desktop -f prev.local
        '';

        "config/sxhkdrc" = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        "config/bspwm-colors.sh" = {
          text = ''
            ${lib.concatStringsSep "\n"
            (lib.attrsets.mapAttrsToList (key: value: ''${key}="${value}"'')
              theme)}
          '';
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
        "scripts/color-pick.sh" = {
          source = ./scripts/color-pick.sh;
          mode = "0755";
        };
        "scripts/takeshot.sh" = {
          source = ./scripts/takeshot.sh;
          mode = "0755";
        };
        "scripts/recorder.sh" = {
          source = ./scripts/recorder.sh;
          mode = "0755";
        };

        # "scripts/bspwm_borders.sh" = {
        #   source = ./scripts/bspwm_borders.sh;
        #   mode = "0755";
        # };
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
        "scripts/bspwm_center_window.sh" = {
          source = ./scripts/bspwm_center_window.sh;
          mode = "0755";
        };
        "scripts/bspwm-borders.sh" = {
          source = ./scripts/bspwm-borders.sh;
          mode = "0755";
        };
        "scripts/bspwm-move-monitors-nodes.sh" = {
          source = ./scripts/bspwm-move-monitors-nodes.sh;
          mode = "0755";
        };

        "scripts/projects/bspwm_dangerp.sh" = {
          source = ./scripts/bspwm_dangerp.sh;
          mode = "0755";
        };
        "scripts/projects/bspwm_tas.sh" = {
          source = ./scripts/bspwm_tas.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xsession = {
        enable = true;
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
