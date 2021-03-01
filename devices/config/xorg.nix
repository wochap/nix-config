{ config, pkgs, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
in
{
  imports = [
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
          source = ./dotfiles/bspwm_external_rules.sh;
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
          greeters.gtk.enable = true;
          greeters.gtk.cursorTheme.name = "capitaine-cursors";
          greeters.gtk.cursorTheme.package = pkgs.capitaine-cursors;
          greeters.gtk.iconTheme.name = "WhiteSur-dark";
          greeters.gtk.iconTheme.package = localPkgs.whitesur-dark-icons;
          greeters.gtk.theme.name = "WhiteSur-dark";
          greeters.gtk.theme.package = localPkgs.whitesur-dark-theme;
          greeters.gtk.cursorTheme.size = 24;
          greeters.gtk.extraConfig = ''
            font-name=Roboto 9
          '';
          greeters.gtk.indicators = [
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

    # Hide cursor automatically
    services.unclutter = {
      enable = true;
    };

    # Hide cursor when typing
    services.xbanish.enable = true;

    services.xserver.useGlamor = true;
  };
}
