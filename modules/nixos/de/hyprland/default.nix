{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.hyprland;
  inherit (config._custom.globals) themeColors;
  hyprland-focus-toggle = pkgs.writeTextFile {
    name = "hyprland-focus-toggle";
    destination = "/bin/hyprland-focus-toggle";
    executable = true;
    text = builtins.readFile ./scripts/hyprland-focus-toggle.sh;
  };
in {
  options._custom.hyprland = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _custom.wm.greetd = {
      enable = lib.mkDefault true;
      cmd = "Hyprland";
    };

    _custom.hm = {
      imports = [
        # already in hm repository master branch
        inputs.hyprland.homeManagerModules.default
      ];

      _custom.programs.waybar = {
        settings.mainBar = {
          modules-left =
            [ "hyprland/workspaces" "keyboard-state" "hyprland/submap" ];
          modules-center = [ "hyprland/window" ];
        };
      };

      home = {
        sessionVariables = {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
        };
        packages = [ hyprland-focus-toggle ];
      };

      xdg.configFile = {
        "hyprland/scripts/autostart.sh" = {
          executable = true;
          source = ./scripts/autostart.sh;
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = ''
          ${lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList (key: value: "${"$"}${key}=${value}")
            themeColors)}

          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}
        '';
        # TODO: fix build
        # plugin = ${inputs.hyprland-plugins.packages.${pkgs.hostPlatform.system}.borders-plus-plus}/lib/libborders-plus-plus.so
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
    };
  };
}
