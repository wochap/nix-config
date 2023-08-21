{ config, lib, pkgs, ... }:

let
  cfg = config._custom.xorgWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/xorg-wm/users/mixins/rofi";
  rofi-config-colors = ''
    * {
    ${lib.concatStringsSep "\n"
    (lib.attrsets.mapAttrsToList (key: value: "  ${key}: ${value};") theme)}
    }
  '';
  rofi-emoji = pkgs.writeTextFile {
    name = "rofi-emoji";
    destination = "/bin/rofi-emoji";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      rofi \
        -config "$HOME/.config/rofi/config-one-line-emoji.rasi" \
        -modi emoji \
        -show emoji \
        -emoji-format '{emoji}' \
        -plugin-path ${pkgs.rofi-emoji}/lib/rofi
    '';
  };
  rofi-calc = pkgs.writeTextFile {
    name = "rofi-calc";
    destination = "/bin/rofi-calc";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      rofi \
        -config "$HOME/.config/rofi/config-multi-line.rasi" \
        -no-sort \
        -p "calc" \
        -modi calc \
        -show calc \
        -plugin-path ${pkgs.rofi-calc}/lib/rofi \
        -calc-command "echo -n '{result}' | wl-copy"
    '';
  };
  rofi-launcher = pkgs.writeTextFile {
    name = "rofi-launcher";
    destination = "/bin/rofi-launcher";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      rofi \
        -config "$HOME/.config/rofi/config-one-line.rasi" \
        -show drun
    '';
  };
  rofi-powermenu = pkgs.writeTextFile {
    name = "rofi-powermenu";
    destination = "/bin/rofi-powermenu";
    executable = true;
    text = builtins.readFile ./scripts/rofi-power-menu.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        libqalculate # rofi-calc dependency
        pkgs.rofi-calc
        pkgs.rofi-emoji
        rofi
        rofi-calc
        rofi-emoji
        rofi-launcher
        rofi-powermenu
      ];
      etc = {
        "scripts/rofi-nm.sh" = {
          source = ./scripts/rofi-nm.sh;
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
        "scripts/rofi-hidden-windows.sh" = {
          source = ./scripts/rofi-hidden-windows.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "rofi/colors.rasi".text = rofi-config-colors;
        "rofi/config-192-dpi.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/config-192-dpi.rasi";
        "rofi/rofi-96-dpi.rasi".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/rofi-96-dpi.rasi";
        "rofi/rofi-help-theme.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/rofi-help-theme.rasi";
        "rofi/config-multi-line.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/config-multi-line.rasi";
        "rofi/config-one-line.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/config-one-line.rasi";
        "rofi/config-one-line-emoji.rasi".source = mkOutOfStoreSymlink
          "${currentDirectory}/dotfiles/config-one-line-emoji.rasi";
      };
    };
  };
}
