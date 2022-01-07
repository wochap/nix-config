{ config, lib, pkgs, ... }:

let
  userName = config._userName;
in
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
              -theme /etc/config/rofi-calc-theme.rasi \
              -modi calc \
              -show calc \
              -plugin-path ${pkgs.rofi-calc}/lib/rofi \
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
        "scripts/rofi-hidden-windows.sh" = {
          source = ./scripts/rofi-hidden-windows.sh;
          mode = "0755";
        };

        "config/rofi-powermenu-theme.rasi" = {
          source = ./dotfiles/rofi-powermenu-theme.rasi;
          mode = "0755";
        };
        "config/rofi-launcher-theme.rasi" = {
          source = ./dotfiles/rofi-launcher-theme.rasi;
          mode = "0755";
        };
        "config/rofi-calc-theme.rasi" = {
          source = ./dotfiles/rofi-calc-theme.rasi;
          mode = "0755";
        };
        "config/rofi-emoji-theme.rasi" = {
          source = ./dotfiles/rofi-emoji-theme.rasi;
          mode = "0755";
        };
        "config/rofi-help-theme.rasi" = {
          source = ./dotfiles/rofi-help-theme.rasi;
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
    home-manager.users.${userName} = {
      programs.rofi.enable = true;
    };
  };
}
