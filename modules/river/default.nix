{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.river;
  inherit (globals) themeColors;
  scripts = import ./scripts { inherit config pkgs lib; };
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
in {
  options._custom.river = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [

      (final: prev: {
        river = prev.river.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "riverwm";
            repo = "river";
            rev = "5ce2ca1bc0411b43e94e8a1dfdf3a90a5dc7fd20";
            hash = "sha256-cIcO6owM6eYn+obYVaBOVQpnBx4++KO5Qk5Hzo3GcNs=";
            fetchSubmodules = true;
          };
        });
      })
    ];

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
            ${builtins.readFile ./dotfiles/keybindings}
            ${builtins.readFile ./dotfiles/config}

            riverctl xcursor-theme ${globals.cursor.name} ${
              toString globals.cursor.size
            } 

            riverctl background-color 0x${unwrapHex themeColors.background}

            riverctl border-color-focused 0x${unwrapHex themeColors.purple}
            riverctl border-color-unfocused 0x${unwrapHex themeColors.selection}
            riverctl border-color-urgent 0x${unwrapHex themeColors.pink}
          '';
          executable = true;
        };
      };
    };
  };
}
