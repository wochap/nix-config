{ config, pkgs, ... }:

{
  config = {
    environment.etc = {
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
            -theme /etc/rofi-theme.rasi \
            -modi calc \
            -show calc \
            -plugin-path ${pkgs.rofi-calc}/lib/rofi \
            -theme-str 'listview { columns: 1; lines: 8; }' \
            -theme-str 'window { width: 15em; }' \
            -theme-str 'prompt { font: "Iosevka 20"; margin: -10px 0 0 0; }' \
            -no-show-match \
            -no-sort \
            -calc-command "echo -n '{result}' | xclip -selection clipboard"
        '';
        mode = "0755";
      };
      "sxhkd_launcher.sh" = {
        source = ./scripts/sxhkd_launcher.sh;
        mode = "0755";
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
