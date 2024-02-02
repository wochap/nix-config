{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  cfg = config._custom.sway;
  inherit (config._custom.globals) themeColors;
  scripts = import ./scripts { inherit config pkgs lib; };
in {
  options._custom.sway = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.wm.greetd = lib.mkIf cfg.isDefault {
      enable = lib.mkDefault true;
      cmd = "sway";
    };

    environment = {
      systemPackages = with pkgs; [
        wlprop
        scripts.sway-focus-toggle

        # gksu
      ];

      sessionVariables = lib.mkIf cfg.isDefault {
        XDG_CURRENT_DESKTOP = "sway";
        XDG_SESSION_DESKTOP = "sway";
      };

      etc = {
        "libinput-gestures.conf".text = ''
          gesture swipe left 3 swaymsg workspace next_on_output
          gesture swipe right 3 swaymsg workspace prev_on_output
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

    _custom.hm = {
      wayland.windowManager.sway = {
        enable = true;
        systemd.enable = true;
        systemd.xdgAutostart = true;
        wrapperFeatures.gtk = true;
        extraOptions = [ "--debug" "--unsupported-gpu" ];
        config.bars = lib.mkForce [ ];
        extraConfig = ''
          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}

          seat * {
            xcursor_theme ${globals.cursor.name} ${toString globals.cursor.size}
          }

          #### SWAY theme ####
          #                         title-border               title-bg                      title-text                  indicator             window-border
          client.focused            ${themeColors.primary}     ${themeColors.primary}        ${themeColors.background}   ${themeColors.cyan}   ${themeColors.primary}
          client.unfocused          ${themeColors.selection}   ${themeColors.selection}      ${themeColors.foreground}   ${themeColors.cyan}   ${themeColors.selection}
          client.focused_inactive   ${themeColors.comment}     ${themeColors.comment}        ${themeColors.foreground}   ${themeColors.cyan}   ${themeColors.comment}
          client.urgent             ${themeColors.pink}        ${themeColors.pink}           ${themeColors.background}   ${themeColors.cyan}   ${themeColors.pink}
        '';
      };

      programs.waybar = lib.mkIf cfg.isDefault {
        settings.mainBar = {
          modules-left = [
            "sway/workspaces"
            "custom/scratchpad_indicator"
            "keyboard-state"
            "sway/mode"
          ];
          modules-center = [ "sway/window" ];
        };
      };

      services.swayidle.timeouts = lib.mkIf cfg.isDefault (lib.mkAfter [
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
      ]);
    };
  };
}
