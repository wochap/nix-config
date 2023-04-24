{ config, lib, pkgs, ... }:

let
  cfg = config._custom.waylandWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/rofi";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        rofi-wayland
        rofi-calc
        rofi-emoji
      ];
      etc = {
        "scripts/rofi-calc.sh" = {
          text = ''
            #!/usr/bin/env bash

            rofi \
              -modi calc \
              -show calc \
              -plugin-path ${pkgs.rofi-calc}/lib/rofi \
              -calc-command "echo -n '{result}' | wl-copy" \
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
        "rofi/rofi-emoji-theme.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/rofi-emoji-theme.rasi";
      };
    };
  };
}
