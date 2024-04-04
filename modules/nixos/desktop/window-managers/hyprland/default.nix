{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom.globals) themeColors;

  hyprlandFinal = inputs.hyprland.packages."${system}".hyprland;
  hyprlandXdpFinal =
    inputs.hyprland-xdp.packages.${system}.xdg-desktop-portal-hyprland;
  hyprland-focus-toggle = pkgs.writeScriptBin "hyprland-focus-toggle"
    (builtins.readFile ./scripts/hyprland-focus-toggle.sh);
in {
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault "Hyprland";
    environment.etc = {
      "greetd/environments".text = lib.mkAfter ''
        Hyprland
      '';
      "greetd/sessions/hyprland.dekstop".source =
        "${hyprlandFinal}/share/wayland-sessions/hyprland.desktop";
    };

    programs.hyprland = {
      enable = true;
      package = hyprlandFinal;
      portalPackage = hyprlandXdpFinal;
    };

    xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];

    _custom.hm = lib.mkMerge [
      {
        home.packages = [ hyprland-focus-toggle ];

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
        };

        systemd.user.services.xdg-desktop-portal-hyprland = {
          Unit = {
            Description = "Portal service (Hyprland implementation)";
            PartOf = "graphical-session.target";
            After = "graphical-session.target";
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            PassEnvironment = [
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
              "QT_QPA_PLATFORMTHEME"
              "PATH"
            ];
            Type = "dbus";
            BusName = "org.freedesktop.impl.portal.desktop.hyprland";
            ExecStart =
              "${hyprlandXdpFinal}/libexec/xdg-desktop-portal-hyprland";
            Restart = "on-failure";
            Slice = "session.slice";
          };
        };
      }

      (lib.mkIf cfg.isDefault {
        services.swayidle.timeouts = lib.mkAfter [
          {
            timeout = 180;
            command =
              ''if ! pgrep swaylock; then chayang -d 5 && wlopm --off "*"; fi'';
            resumeCommand = ''if ! pgrep swaylock; then wlopm --on "*"; fi'';
          }
          {
            timeout = 15;
            command = ''if pgrep swaylock; then wlopm --off "*"; fi'';
            resumeCommand = ''if pgrep swaylock; then wlopm --on "*"; fi'';
          }
        ];
      })
    ];
  };
}
