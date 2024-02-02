{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  cfg = config._custom.river;
  inherit (globals) themeColors;
  scripts = import ./scripts { inherit config pkgs lib; };
  inherit (lib._custom) unwrapHex;
  river-shifttags = pkgs.callPackage ./packages/river-shifttags.nix { };
  riverwm-utils = pkgs.callPackage ./packages/riverwm-utils.nix { };
in {
  options._custom.river = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        river = prev.river.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "riverwm";
            repo = "river";
            rev = "c16628c7f57c51d50f2d10a96c265fb0afaddb02";
            hash = "sha256-E3Xtv7JeCmafiNmpuS5VuLgh1TDAbibPtMo6A9Pz6EQ=";
            fetchSubmodules = true;
          };
        });
      })
    ];

    _custom.wm.greetd = lib.mkIf cfg.isDefault {
      enable = lib.mkDefault true;
      cmd = "river";
    };

    environment = {
      systemPackages = with pkgs; [
        lswt
        ristate
        river
        river-shifttags
        river-tag-overlay
        rivercarro
        # riverwm-utils
        scripts.river-focus-toggle
        wlopm # turn off/on screen
        wlrctl # focus window
      ];

      sessionVariables = lib.mkIf cfg.isDefault {
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

    _custom.hm = {
      programs.waybar = lib.mkIf cfg.isDefault {
        settings.mainBar = {
          modules-left = [ "river/tags" "river/mode" "keyboard-state" ];
          modules-center = [ "river/window" ];
        };
      };

      xdg.configFile = {
        "river/init" = {
          text = ''
            riverctl xcursor-theme ${globals.cursor.name} ${
              toString globals.cursor.size
            }

            riverctl background-color 0x${unwrapHex themeColors.background}

            riverctl border-color-focused 0x${unwrapHex themeColors.primary}
            riverctl border-color-unfocused 0x${unwrapHex themeColors.selection}
            riverctl border-color-urgent 0x${unwrapHex themeColors.pink}

            ${builtins.readFile ./dotfiles/keybindings}
            ${builtins.readFile ./dotfiles/config}
          '';
          executable = true;
        };
      };

      services.swayidle.timeouts = lib.mkIf cfg.isDefault (lib.mkAfter [
        {
          timeout = 195;
          command = ''wlopm --off "*"'';
          resumeCommand = ''wlopm --on "*"'';
        }
        {
          timeout = 15;
          command = ''if pgrep swaylock; then wlopm --off "*"; fi'';
          resumeCommand = ''if pgrep swaylock; then wlopm --on "*"; fi'';
        }
      ]);

      systemd.user.services.river-tag-overlay = lib.mkIf cfg.isDefault {
        Unit = {
          Description = "A pop-up showing tag status";
          Documentation = "https://git.sr.ht/~leon_plickat/river-tag-overlay";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          # PassEnvironment = "PATH";
          ExecStart = ''
            ${pkgs.river-tag-overlay}/bin/river-tag-overlay \
              --tag-amount 32 \
              --tags-per-row 8 \
              --timeout 300 \
              --anchors 0:1:1:1 \
              --margins 0:0:7:0 \
              --border-width 2 \
              --square-border-width 1 \
              --background-colour 0x${unwrapHex themeColors.background} \
              --border-colour 0x${unwrapHex themeColors.comment} \
              --square-active-background-colour 0xDCC5FC \
              --square-active-border-colour 0x${unwrapHex themeColors.primary} \
              --square-active-occupied-colour 0x${
                unwrapHex themeColors.primary
              } \
              --square-inactive-background-colour 0x585C74 \
              --square-inactive-border-colour 0x${
                unwrapHex themeColors.selection
              } \
              --square-inactive-occupied-colour 0x${
                unwrapHex themeColors.selection
              } \
              --square-urgent-background-colour 0xFF8585 \
              --square-urgent-border-colour 0x${unwrapHex themeColors.red} \
              --square-urgent-occupied-colour 0x${unwrapHex themeColors.red} \
          '';
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

    };
  };
}
