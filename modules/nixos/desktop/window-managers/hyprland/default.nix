{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom.globals) themeColors;

  hyprlandFinal = inputs.hyprland.packages."${system}".hyprland;
  hyprland-focus-toggle = pkgs.writeScriptBin "hyprland-focus-toggle"
    (builtins.readFile ./scripts/hyprland-focus-toggle.sh);
in {
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault "Hyprland";

    programs.hyprland = {
      enable = true;
      package = hyprlandFinal;
      portalPackage =
        inputs.hyprland-xdp.packages.${system}.xdg-desktop-portal-hyprland;
    };

    xdg.portal.config.hyprland.default = [ "gtk" "hyprland" ];

    _custom.hm = lib.mkMerge [
      {
        home.packages = [ hyprland-focus-toggle ];

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
          # plugins =
          #   [ inputs.hyprland-plugins.packages."${system}".borders-plus-plus ];
        };
      }

      (lib.mkIf cfg.isDefault {
        home.sessionVariables = {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
        };

        xdg.configFile."hypr/libinput-gestures.conf".text = ''
          gesture swipe left 3 hyprctl dispatch workspace e+1
          gesture swipe right 3 hyprctl dispatch workspace e-1
        '';

        services.swayidle.timeouts = lib.mkAfter [
          {
            timeout = 185;
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
              "${pkgs.libinput-gestures}/bin/libinput-gestures -c $HOME/.config/hypr/libinput-gestures.conf";
            Type = "simple";
          };
        };
      })
    ];
  };
}
