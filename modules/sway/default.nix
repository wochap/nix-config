{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.sway;
  theme = config._theme;
  scripts = import ./scripts { inherit config pkgs lib; };
in {
  options._custom.sway = { enable = lib.mkEnableOption "activate SWAY"; };

  config = lib.mkIf cfg.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = [ ]; # block rxvt
      extraOptions = [ "--debug" ];
    };

    environment = {
      systemPackages = with pkgs;
        [
          scripts.sway-focus-toggle

          # gksu
        ];

      sessionVariables = {
        XDG_CURRENT_DESKTOP = "sway";
        XDG_SESSION_DESKTOP = "sway";
      };

      etc = {
        "libinput-gestures.conf".text = ''
          gesture swipe left 3 swaymsg workspace next_on_output
          gesture swipe right 3 swaymsg workspace prev_on_output
        '';

        "sway/config".text = ''
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

        "scripts/sway-autostart.sh" = {
          source = ./scripts/sway-autostart.sh;
          mode = "0755";
        };

        "scripts/projects/sway-dangerp.sh" = {
          source = ./scripts/sway-dangerp.sh;
          mode = "0755";
        };
      };
    };

    _custom.greetd = {
      enable = true;
      cmd = "sway";
    };

    home-manager.users.${userName}.services.swayidle.timeouts = lib.mkAfter [
      {
        timeout = 195;
        command = ''swaymsg "output * dpms off"'';
        resumeCommand = ''swaymsg "output * dpms on"'';
      }
      {
        timeout = 15;
        command = ''if pgrep swaylock; then swaymsg "output * dpms off"; fi'';
        resumeCommand =
          ''if pgrep swaylock; then swaymsg "output * dpms on"; fi'';
      }
    ];
  };
}
