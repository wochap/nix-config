{ config, inputs, pkgs, lib, ... }:

let
  # inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.dwl;
  # inherit (globals) themeColors;
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
            rev = "aa784c4479bbed09c944621f5fb30854cfed9990";
            hash = "sha256-e07wD9iUNyzezzMTPPrhz7vGXo/yYR9Xl4W1Yff/gBE=";
          };
        });
      })
    ];

    _custom.wm.greetd = {
      enable = lib.mkDefault true;
      cmd = "dwl > ~.cache/dwltags";
    };

    environment = {
      systemPackages = with pkgs; [
        (dwl.override { conf = ./dotfiles/config.def.h; })

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
        # "scripts/projects/dwl-dangerp.sh" = {
        #   source = ./scripts/dwl-dangerp.sh;
        #   mode = "0755";
        # };
      };
    };

    home-manager.users.${userName} = {
      _custom.programs.waybar = {
        settings.mainBar = {
          modules-left = [ "dwl/tags" "keyboard-state" ];
          modules-center = [];
        };
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
