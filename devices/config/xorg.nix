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
        "play_notification.sh" = {
          text = ''
            #! ${pkgs.bash}/bin/bash
            ${pkgs.pulseaudio}/bin/paplay /etc/notification.flac
          '';
          mode = "0755";
        };
        "notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };
        "blop.wav" = {
          source = ./assets/blop.wav;
          mode = "0755";
        };
        "eww_bright.sh" = {
          source = ./scripts/eww_bright.sh;
          mode = "0755";
        };
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
        "autostart.sh" = {
          source = ./scripts/autostart.sh;
          mode = "0755";
        };
        "desktop_4.sh" = {
          source = ./scripts/desktop_4.sh;
          mode = "0755";
        };
        sxhkdrc = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        "powermenu.rasi" = {
          source = ./dotfiles/powermenu.rasi;
          mode = "0755";
        };
        sxhkd-help = {
          source = ./scripts/sxhkd-help.sh;
          mode = "0755";
        };
        sxhkd-calc = {
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
        sxhkd-launcher = {
          source = ./scripts/sxhkd-launcher.sh;
          mode = "0755";
        };
        "powermenu.sh" = {
          source = ./scripts/powermenu.sh;
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
          # greeters.webkit2 = {
          #   enable = true;
          #   detectThemeErrors = false;
          #   debugMode = true;
          #   # webkitTheme = fetchTarball {
          #   #   url = "https://github.com/Litarvan/lightdm-webkit-theme-litarvan/releases/download/v3.0.0/lightdm-webkit-theme-litarvan-3.0.0.tar.gz";
          #   #   sha256 = "0q0r040vxg1nl51wb3z3r0pl7ymhyhp1lbn2ggg7v3pa563m4rrv";
          #   # };
          #   webkitTheme = pkgs.fetchzip {
          #     stripRoot = false;
          #     url = "https://github.com/manilarome/lightdm-webkit2-theme-glorious/releases/download/v2.0.5/lightdm-webkit2-theme-glorious-2.0.5.tar.gz";
          #     sha256 = "1y2jln72dabhzisrdb7fi0rkqv54paa8h9q0r8h7g9050ahp9bsf";
          #   };
          # };
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
    services.unclutter = {
      enable = true;
    };

    # Hide cursor when typing
    services.xbanish.enable = true;

    services.xserver.useGlamor = true;
  };
}
