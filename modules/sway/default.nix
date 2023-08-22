{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.sway;
  inherit (config._custom.globals) themeColors;
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
          client.focused            ${themeColors.purple}      ${themeColors.purple}         ${themeColors.background}   ${themeColors.cyan}   ${themeColors.purple}
          client.unfocused          ${themeColors.selection}   ${themeColors.selection}      ${themeColors.foreground}   ${themeColors.cyan}   ${themeColors.selection}
          client.focused_inactive   ${themeColors.comment}     ${themeColors.comment}        ${themeColors.foreground}   ${themeColors.cyan}   ${themeColors.comment}
          client.urgent             ${themeColors.pink}        ${themeColors.pink}           ${themeColors.background}   ${themeColors.cyan}   ${themeColors.pink}
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
