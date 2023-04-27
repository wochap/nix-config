{ config, lib, pkgs, ... }:

let
  cfg = config._custom.waylandWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/rofi";
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
        -p "" \
        -modi calc \
        -show calc \
        -plugin-path ${pkgs.rofi-calc}/lib/rofi \
        -theme-str 'prompt { font: "woos 18px"; }' \
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
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [
          libqalculate # rofi-calc dependency
          pkgs.rofi-calc
          pkgs.rofi-emoji
          rofi-calc
          rofi-emoji
          rofi-launcher
          rofi-powermenu
          rofi-wayland
        ];
      };
      xdg.configFile = {
        "rofi/colors.rasi".text = rofi-config-colors;
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
