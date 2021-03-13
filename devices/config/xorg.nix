{ config, pkgs, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
in
{
  imports = [
    ./modules/lightdm-webkit2-greeter
    ./common.nix
  ];

  config = {
    _displayServer = "xorg";

    # Setup DE bspwm and sxhkdrc
    environment = {
      etc = {
        "notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };
        "blop.wav" = {
          source = ./assets/blop.wav;
          mode = "0755";
        };

        "fix_caps_lock_delay.sh" = {
          source = ./scripts/fix_caps_lock_delay.sh;
          mode = "0755";
        };
        "play_notification.sh" = {
          text = ''
            #! ${pkgs.bash}/bin/bash
            ${pkgs.pulseaudio}/bin/paplay /etc/notification.flac
          '';
          mode = "0755";
        };

        # "eww_bright.sh" = {
        #   source = ./scripts/eww_bright.sh;
        #   mode = "0755";
        # };
        "eww_vol_icon.sh" = {
          source = ./scripts/eww_vol_icon.sh;
          mode = "0755";
        };
        "eww_vol.sh" = {
          source = ./scripts/eww_vol.sh;
          mode = "0755";
        };

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
        "sxhkd_help.sh" = {
          source = ./scripts/sxhkd_help.sh;
          mode = "0755";
        };
        "sxhkd_calc.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
              -theme ~/.config/rofi-theme.rasi \
              -modi calc \
              -show calc \
              -plugin-path ${pkgs.rofi-calc}/lib/rofi \
              -theme-str 'listview { columns: 1; lines: 8; }' \
              -theme-str 'window { width: 15em; }' \
              -theme-str 'prompt { font: "Iosevka 20"; margin: -10px 0 0 0; }' \
              -no-show-match \
              -no-sort \
              -calc-command "echo -n '{result}' | xclip"
          '';
          mode = "0755";
        };
        "sxhkd_launcher.sh" = {
          source = ./scripts/sxhkd_launcher.sh;
          mode = "0755";
        };

        "powermenu.sh" = {
          source = ./scripts/powermenu.sh;
          mode = "0755";
        };
        "powermenu.rasi" = {
          source = ./dotfiles/powermenu.rasi;
          mode = "0755";
        };
      };
    };
    services.xserver = {
      enable = true;
      exportConfiguration = true;
      windowManager.bspwm = {
        enable = true;
        configFile = "/etc/bspwmrc";
        sxhkd.configFile = "/etc/sxhkdrc";
      };
      desktopManager = {
        xterm.enable = false;
      };
      displayManager = {
        defaultSession = "none+bspwm";
        lightdm = {
          enable = true;
          background = ./assets/wallpaper.jpg;
          greeters.webkit2 = {
            enable = false;
            detectThemeErrors = false;
            debugMode = true;
            webkitTheme = pkgs.fetchzip {
              stripRoot = true;
              url = "https://github.com/wochap/lightdm-webkit2-theme-glorious/archive/7ce9c6c04a5676481fff03d585efa6c97bd40ad2.zip";
              sha256 = "0zl1fcbwfhlpjxn2zq50bffsvgkp49ch0k2djyhkbnih2fbqdykm";
            };
            branding = {
              userImage = ./assets/profile.jpg;
            };
          };
          greeters.gtk = {
            enable = true;
            cursorTheme.name = "capitaine-cursors";
            cursorTheme.package = pkgs.capitaine-cursors;
            iconTheme.name = "WhiteSur-dark";
            iconTheme.package = localPkgs.whitesur-dark-icons;
            theme.name = "WhiteSur-dark";
            theme.package = localPkgs.whitesur-dark-theme;
            cursorTheme.size = 24;
            extraConfig = ''
              font-name=Roboto 9
            '';
            indicators = [
              "~host"
              "~spacer"
              "~clock"
              "~spacer"
              "~session"
              "~language"
              "~a11y"
              "~power"
            ];
          };
        };
      };
    };

    # Hide cursor automatically
    services.unclutter.enable = true;

    # Hide cursor when typing
    services.xbanish.enable = true;
    services.xbanish.arguments = "-i shift -i control -i super -i alt -i space";

    services.xserver.useGlamor = true;
  };
}
