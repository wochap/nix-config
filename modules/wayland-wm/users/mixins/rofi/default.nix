{ config, lib, pkgs, ... }:

let
  cfg = config._custom.waylandWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/xorg-wm/users/mixins/rofi";
in {
  config = lib.mkIf cfg.enable {
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
        "scripts/rofi-calc.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
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

            rofi \
              -config "$HOME/.config/rofi/rofi-emoji-theme.rasi" \
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
        "rofi/rofi-emoji-theme.rasi".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/rofi-emoji-theme.rasi";
        "rofi/rofi-help-theme.rasi".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/rofi-help-theme.rasi";
      };
    };
  };
}
