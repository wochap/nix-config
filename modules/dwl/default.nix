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
          version = "0.4-next";

          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = "8280a92eba24ae4d97429a5df56398d805d53b8c";
            hash = "sha256-r2kYENymlLVU6Pi+/x9N4gh37+AZNDMAEITtH0BImxw=";
          };

          buildInputs = with pkgs.unstable; [
            libinput
            xorg.libxcb
            libxkbcommon
            pixman
            wayland
            wayland-protocols
            wlroots_0_16

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
        (unstable.dwl.override { conf = ./dotfiles/config.def.h; })
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
