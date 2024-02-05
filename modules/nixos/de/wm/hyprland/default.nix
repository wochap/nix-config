{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.de.hyprland;
  inherit (config._custom.globals) userName themeColors;
  hyprlandFinal = inputs.hyprland.packages."${system}".hyprland;
  hyprland-focus-toggle = pkgs.writeScriptBin "hyprland-focus-toggle"
    (builtins.readFile ./scripts/hyprland-focus-toggle.sh);
in {
  options._custom.de.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.de.greetd.cmd = lib.mkIf cfg.isDefault "Hyprland";

    programs.hyprland = {
      enable = true;
      package = hyprlandFinal;
      portalPackage =
        inputs.hyprland-xdp.packages.${system}.xdg-desktop-portal-hyprland;
    };

    xdg.portal.config.hyprland.default = [ "gtk" "hyprland" ];

    _custom.hm = {
      programs.waybar.settings.mainBar = {
        modules-left =
          [ "hyprland/workspaces" "keyboard-state" "hyprland/submap" ];
        modules-center = [ "hyprland/window" ];
      };

      home = {
        sessionVariables = {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
        };
        packages = [ hyprland-focus-toggle ];
      };

      xdg.configFile."hypr/libinput-gestures.conf".text = ''
        gesture swipe left 3 hyprctl dispatch workspace e+1
        gesture swipe right 3 hyprctl dispatch workspace e-1
      '';

      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprlandFinal;
        systemd.enable = false;
        extraConfig = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "${"$"}${key}=${lib._custom.unwrapHex value}")
            themeColors)}

          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}
        '';
        plugins =
          [ inputs.hyprland-plugins.packages."${system}".borders-plus-plus ];
      };

      services.swayidle.timeouts = lib.mkAfter [
        {
          timeout = 195;
          command = "hyprctl dispatch dpms off";
          resumeCommand = "hyprctl dispatch dpms on";
        }
        {
          timeout = 15;
          command = "if pgrep swaylock; then hyprctl dispatch dpms off; fi";
          resumeCommand =
            "if pgrep swaylock; then hyprctl dispatch dpms on; fi";
        }
      ];

      systemd.user.services.libinput-gestures = lib._custom.mkWaylandService {
        Unit = {
          Description = "Actions gestures on your touchpad using libinput";
          Documentation = "https://github.com/bulletmark/libinput-gestures";
        };
        Service = {
          PassEnvironment = [ "PATH" "HOME" ];
          ExecStart =
            "${pkgs.libinput-gestures}/bin/libinput-gestures -c /home/${userName}/.config/hypr/libinput-gestures.conf";
          Type = "simple";
        };
      };
    };
  };
}
