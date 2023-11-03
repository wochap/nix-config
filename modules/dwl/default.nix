{ config, inputs, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.dwl;
  inherit (config._custom.globals) themeColors cursor;
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

  dwl-waybar = pkgs.writeTextFile {
    name = "dwl-waybar";
    destination = "/bin/dwl-waybar";
    executable = true;

    text = builtins.readFile ./scripts/dwl-waybar.sh;
  };
in {
  options._custom.dwl = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        # install my patched dwl
        dwl = prev.dwl.overrideAttrs (oldAttrs: rec {
          version = "0.4-next";
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = "115d71479200ca8a3223d5911c3ed6ed33ce7c83";
            hash = "sha256-0lDI2MRqvrek7ZdKwE/pV6S1aX7VhzG4rlZ87bT4Wsw=";
            # IPC v2
            # rev = "b18cf6662705bc431d68accaf13476315663d55c";
            # hash = "sha256-HYbnWEw+H241jdBO9Qs8SOpOIumH6mN40jOwCcqYZ5M=";
          };
        });
      })
    ];

    _custom.wm.greetd = {
      enable = lib.mkDefault true;
      cmd = "dwl > /home/${userName}/.cache/dwltags";
    };

    environment = {
      systemPackages = with pkgs; [
        (unstable.dwl.override {
          conf = ''
            ${builtins.readFile ./dotfiles/config.def.h}

            static const float bordercolor[] = COLOR(0x${
              unwrapHex themeColors.selection
            }ff);
            static const float focuscolor[] = COLOR(0x${
              unwrapHex themeColors.primary
            }ff);
            static const float urgentcolor[] = COLOR(0x${
              unwrapHex themeColors.red
            }ff);
            static const char cursortheme[] = "${cursor.name}";
            static const unsigned int cursorsize = ${toString cursor.size};
          '';
        })
        dwl-waybar
        # _custom.dwl-state

        lswt # doesn't work on dwl
        wlopm
        wlrctl

        # for testing dwl
        bemenu
        foot
      ];

      sessionVariables = {
        XDG_CURRENT_DESKTOP = "dwl";
        XDG_SESSION_DESKTOP = "dwl";
      };

      etc = {
        "scripts/dwl-autostart.sh" = {
          source = ./scripts/dwl-autostart.sh;
          mode = "0755";
        };

        # scripts to open projects blazingly fast
        "scripts/projects/dwl-dangerp.sh" = {
          source = ./scripts/dwl-dangerp.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      _custom.programs.waybar = {
        settings.mainBar = lib.mkMerge ([{
          modules-left = (builtins.map (i: "custom/dwl_tag#${toString i}")
            (builtins.genList (i: i) 9))
            ++ [ "custom/dwl_layout" "custom/dwl_mode" "keyboard-state" ];
          modules-center = [ "custom/dwl_title" ];
          "custom/dwl_layout" = {
            exec = "dwl-waybar '' layout";
            format = "{}";
            escape = true;
            return-type = "json";
          };
          "custom/dwl_title" = {
            exec = "dwl-waybar '' title";
            format = "{}";
            escape = true;
            return-type = "json";
            max-length = 50;
          };
          "custom/dwl_mode" = {
            exec = "dwl-waybar '' mode";
            format = "{}";
            escape = true;
            return-type = "json";
          };
        }] ++ (builtins.map (i: {
          "custom/dwl_tag#${toString i}" = {
            exec = "dwl-waybar '' ${toString i}";
            format = "{}";
            return-type = "json";
          };
        }) (builtins.genList (i: i) 9)));
      };

      services.swayidle.timeouts = lib.mkAfter [
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
      ];

    };
  };
}
