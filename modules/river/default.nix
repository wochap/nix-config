{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.river;
  inherit (config._custom.globals) themeColors;
  scripts = import ./scripts { inherit config pkgs lib; };
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
in {
  options._custom.river = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _custom.wm.greetd = {
      enable = lib.mkDefault true;
      cmd = "river";
    };

    environment = {
      systemPackages = with pkgs; [ wlopm river scripts.river-focus-toggle ];

      sessionVariables = {
        XDG_CURRENT_DESKTOP = "river";
        XDG_SESSION_DESKTOP = "river";
      };

      etc = {
        "scripts/river-autostart.sh" = {
          source = ./scripts/river-autostart.sh;
          mode = "0755";
        };

        # scripts to open projects blazingly fast
        "scripts/projects/river-dangerp.sh" = {
          source = ./scripts/river-dangerp.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      _custom.programs.waybar = {
        settings.mainBar = {
          modules-left = [ "river/tags" "keyboard-state" "river/mode" ];
          modules-center = [ "river/window" ];
        };
      };

      xdg.configFile = {
        "river/init" = {
          text = ''
            riverctl background-color 0x${unwrapHex themeColors.background}

            riverctl border-color-focused 0x${unwrapHex themeColors.purple}
            riverctl border-color-unfocused 0x${unwrapHex themeColors.selection}
            riverctl border-color-urgent 0x${unwrapHex themeColors.pink}

            ${builtins.readFile ./dotfiles/keybindings}
            ${builtins.readFile ./dotfiles/config}
          '';
          executable = true;
        };
      };
    };
  };
}
