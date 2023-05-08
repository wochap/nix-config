{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  cfg = config._custom.hyprland;
  theme = config._theme;
in {
  options._custom.hyprland = {
    enable = lib.mkEnableOption "activate hyprland";
  };

  config = lib.mkIf cfg.enable {
    environment.loginShellInit = lib.mkAfter ''
      if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
        exec Hyprland
      fi
    '';

    home-manager.users.${userName} = {
      home.sessionVariables = { XDG_CURRENT_DESKTOP = "Hyprland"; };

      xdg.configFile = {
        "hyprland/scripts/autostart.sh" = {
          executable = true;
          source = ./scripts/autostart.sh;
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland = {
          enable = true;
          hidpi = true;
        };
        extraConfig = ''
          ${lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList (key: value: "${"$"}${key}=${value}")
            theme)}

          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}
        '';
      };

      services.swayidle.timeouts = lib.mkAfter [{
        timeout = 360;
        command = "hyprctl dispatch dpms off";
        resumeCommand = "hyprctl dispatch dpms on";
      }];
    };
  };
}
