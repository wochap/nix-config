{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.river;
  theme = config._theme;
  scripts = import ./scripts { inherit config pkgs lib; };
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
in {
  options._custom.river = { enable = lib.mkEnableOption "activate river"; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        river

        scripts.river-focus-toggle
        scripts.dbus-wayland-wm-environment
      ];

      etc = {
        "scripts/river-autostart.sh" = {
          source = ./scripts/river-autostart.sh;
          mode = "0755";
        };

        # scripts to open projects blazingly fast
        # "scripts/projects/sway-dangerp.sh" = {
        #   source = ./scripts/sway-dangerp.sh;
        #   mode = "0755";
        # };
      };
    };

    home-manager.users.${userName} = {
      programs.zsh.initExtraFirst = lib.mkAfter ''
        if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
          exec river
        fi
      '';

      xdg.configFile = {

        "river/init" = {
          text = ''
            riverctl background-color 0x${unwrapHex theme.background}

            riverctl border-color-focused 0x${unwrapHex theme.purple}
            riverctl border-color-unfocused 0x${unwrapHex theme.selection}
            riverctl border-color-urgent 0x${unwrapHex theme.pink}

            ${builtins.readFile ./dotfiles/keybindings}
            ${builtins.readFile ./dotfiles/config}
          '';
          executable = true;
        };
      };
    };

  };
}
