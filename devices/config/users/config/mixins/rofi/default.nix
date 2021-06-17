{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        rofi-calc
        rofi-emoji
      ];
      etc = {
        "rofi-update-gaps.sh" = {
          source = ./scripts/rofi-update-gaps.sh;
          mode = "0755";
        };
        "rofi-clipboard.sh" = {
          source = ./scripts/rofi-clipboard.sh;
          mode = "0755";
        };
        "rofi-help.sh" = {
          source = ./scripts/rofi-help.sh;
          mode = "0755";
        };
        "rofi-calc.sh" = {
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
        "rofi-emoji.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
              -theme /etc/rofi-theme.rasi \
              -modi emoji \
              -show emoji \
              -plugin-path ${pkgs.rofi-emoji}/lib/rofi \
              -theme-str 'listview { columns: 2; lines: 15; }' \
              -theme-str 'window { width: 35em; }' \
              -theme-str 'prompt { font: "Iosevka 20"; margin: -10px 0 0 0; }'
          '';
          mode = "0755";
        };
        "rofi-launcher.sh" = {
          source = ./scripts/rofi-launcher.sh;
          mode = "0755";
        };
        "rofi-powermenu.sh" = {
          source = ./scripts/rofi-powermenu.sh;
          mode = "0755";
        };

        "rofi-powermenu-theme.rasi" = {
          source = ./dotfiles/rofi-powermenu-theme.rasi;
          mode = "0755";
        };
        "rofi-theme.rasi" = {
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
