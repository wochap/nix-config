{ config, lib, pkgs, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        rofi-calc
        rofi-emoji
      ];
      etc = {
        "scripts/rofi-custom-options.sh" = {
          source = ./scripts/rofi-custom-options.sh;
          mode = "0755";
        };
        "scripts/rofi-clipboard.sh" = {
          source = ./scripts/rofi-clipboard.sh;
          mode = "0755";
        };
        "scripts/rofi-help.sh" = {
          source = ./scripts/rofi-help.sh;
          mode = "0755";
        };
        "scripts/rofi-wifi.sh" = {
          source = ./scripts/rofi-wifi.sh;
          mode = "0755";
        };
        "scripts/rofi-calc.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
              -theme /etc/config/rofi-theme.rasi \
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
        "scripts/rofi-emoji.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
              -theme /etc/config/rofi-emoji-theme.rasi \
              -modi emoji \
              -show emoji \
              -plugin-path ${pkgs.rofi-emoji}/lib/rofi
          '';
          mode = "0755";
        };
        "scripts/rofi-launcher.sh" = {
          source = ./scripts/rofi-launcher.sh;
          mode = "0755";
        };
        "scripts/rofi-powermenu.sh" = {
          source = ./scripts/rofi-powermenu.sh;
          mode = "0755";
        };

        "config/rofi-powermenu-theme.rasi" = {
          source = ./dotfiles/rofi-powermenu-theme.rasi;
          mode = "0755";
        };
        "config/rofi-emoji-theme.rasi" = {
          source = ./dotfiles/rofi-emoji-theme.rasi;
          mode = "0755";
        };
        "config/rofi-clipboard-theme.rasi" = {
          source = ./dotfiles/rofi-clipboard-theme.rasi;
          mode = "0755";
        };
        "config/rofi-theme.rasi" = {
          source = ./dotfiles/rofi-theme.rasi;
          mode = "0755";
        };
      };
      pathsToLink = [
        "/share/rofi-emoji"
      ];
    };
    home-manager.users.gean = {
      programs.rofi.enable = true;
    };
  };
}
