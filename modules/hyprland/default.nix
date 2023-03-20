{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.hyprland;
  theme = config._theme;
  scripts = import ./scripts { inherit config pkgs lib; };
in {
  options._custom.hyprland = {
    enable = lib.mkEnableOption "activate hyprland";
  };

  config = lib.mkIf cfg.enable {

    environment = {
      systemPackages = with pkgs;
        [
          scripts.dbus-wayland-wm-environment

          # gksu
        ];

      sessionVariables = { XDG_CURRENT_DESKTOP = "sway"; };

      etc = {

        "sway/config".text = "";

        "scripts/sway-autostart.sh" = {
          source = ./scripts/sway-autostart.sh;
          mode = "0755";
        };

        # "scripts/projects/sway-dangerp.sh" = {
        #   source = ./scripts/sway-dangerp.sh;
        #   mode = "0755";
        # };
      };
    };

    home-manager.users.${userName} = {
      wayland.windowManager.hyprland = {
        enable = true;
        xwayland = {
          enable = true;
          hidpi = true;
        };
        extraConfig = ''
          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}

          seat * {
            xcursor_theme ${globals.cursor.name} ${toString globals.cursor.size}
          }

          #### SWAY theme ####
          #                         title-border         title-bg                title-text            indicator       window-border
          client.focused            ${theme.purple}      ${theme.purple}         ${theme.background}   ${theme.cyan}   ${theme.purple}
          client.unfocused          ${theme.selection}   ${theme.selection}    ${theme.foreground}   ${theme.cyan}   ${theme.selection}
          client.focused_inactive   ${theme.comment}     ${theme.comment}        ${theme.foreground}   ${theme.cyan}   ${theme.comment}
          client.urgent             ${theme.pink}        ${theme.pink}           ${theme.background}   ${theme.cyan}   ${theme.pink}

        '';
      };

      programs.zsh.initExtraFirst = lib.mkAfter ''
        if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
          exec hyprland
        fi
      '';
    };
  };
}
