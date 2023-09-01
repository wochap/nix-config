{ config, inputs, pkgs, lib, ... }:

let
  # inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.dwl;
  # inherit (globals) themeColors;

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
        dwl = prev.dwl.overrideAttrs (oldAttrs: rec {
          version = "0.4-wlroots-next";

          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = "e1427d7ad13f96c4291d8b94b98720b4172fdf1e";
            hash = "sha256-9QQptGy5haVhcFGqQ7dMF0gfHvoyb/L+k5InrgJA5SI=";
          };

          buildInputs = with pkgs.unstable; [
            libinput
            xorg.libxcb
            libxkbcommon
            pixman
            wayland
            wayland-protocols

            (wlroots_0_16.overrideAttrs (_: {
              src = fetchFromGitLab {
                domain = "gitlab.freedesktop.org";
                owner = "wlroots";
                repo = "wlroots";
                rev = "2926acf60d80961597fa55ab68c3d15d7bf1980d";
                hash = "sha256-Kkgx6KyJFtQEE4X+bgXlXAaSPnR9dWXGyw9ovf7wUlw=";
              };
              buildInputs = _.buildInputs
                ++ [ pkgs.hwdata pkgs.libdisplay-info ];
            }))

            xorg.libX11
            xorg.xcbutilwm
            xwayland
          ];
        });
      })
    ];

    _custom.wm.greetd = {
      enable = lib.mkDefault true;
      cmd = "dwl > /home/${userName}/.cache/dwltags";
    };

    environment = {
      systemPackages = with pkgs; [
        (unstable.dwl.override { conf = ./dotfiles/wlroots-next-config.def.h; })
        dwl-waybar

        lswt
        wlopm
        wlrctl
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
            ++ [ "custom/dwl_layout" "keyboard-state" ];
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
