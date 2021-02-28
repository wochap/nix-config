{ config, pkgs, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
  nur = import (fetchTarball "https://github.com/nix-community/NUR/archive/1dac356bd823d83dd58917eae0e208d2183f3d4e.zip") {};
  # nur = import (fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {};
in
{
  imports = [
    # nur.repos.metadark.modules.lightdm-webkit2-greeter,
    nur.repos.metadark.modules.services.x11.display-managers.lightdm-greeters.webkit2,
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
          greeters.webkit2 = {
            enable = true;
            # webkitTheme = fetchTarball {
            #   url = "https://github.com/Litarvan/lightdm-webkit-theme-litarvan/releases/download/v3.0.0/lightdm-webkit-theme-litarvan-3.0.0.tar.gz";
            #   sha256 = "0q0r040vxg1nl51wb3z3r0pl7ymhyhp1lbn2ggg7v3pa563m4rrv";
            # };
          };
          greeters.gtk.enable = false;
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
