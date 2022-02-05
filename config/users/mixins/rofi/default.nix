{ config, lib, pkgs, ... }:

let
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/rofi";
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        rofi
        rofi-calc
        rofi-emoji
      ];
      etc = {
        "scripts/rofi-nm.sh" = {
          source = ./scripts/rofi-nm.sh;
          mode = "0755";
        };
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

            # get dpi
            DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

            rofi \
              -dpi "$DPI" \
              -modi calc \
              -show calc \
              -plugin-path ${pkgs.rofi-calc}/lib/rofi \
              -calc-command "echo -n '{result}' | xclip -selection clipboard" \
              -theme-str 'window { width: 20em; }'
          '';
          mode = "0755";
        };
        "scripts/rofi-emoji.sh" = {
          text = ''
            #!/usr/bin/env bash

            # get dpi
            DPI=$(xrdb -query | grep dpi | sed "s/Xft.dpi://" | xargs)

            rofi \
              -config /etc/config/rofi-emoji-theme.rasi \
              -dpi "$DPI" \
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
      pathsToLink = [ "/share/rofi-emoji" ];
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "rofi/colors.rasi".text = ''
          * {
          ${lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList (key: value: "  ${key}: ${value};")
            theme)}
          }
        '';
        "rofi/config.rasi".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.rasi";
      };
    };
  };
}
