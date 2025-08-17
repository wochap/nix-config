{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.dunst;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  dunst-toggle-mode = pkgs.writeScriptBin "dunst-toggle-mode"
    (builtins.readFile ./scripts/dunst-toggle-mode.sh);
  mkThemeDunst = themeColors:
    pkgs.replaceVars ./dotfiles/dunstrc {
      inherit (themeColors)
        backgroundOverlay text border lavender textDimmed red;
    };
  catppuccin-dunst-light-theme-path = mkThemeDunst themeColorsLight;
  catppuccin-dunst-dark-theme-path = mkThemeDunst themeColorsDark;
in {
  options._custom.desktop.dunst.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ reversal-icon-theme ];

    _custom.hm = {
      home = {
        packages = with pkgs; [
          _custom.dunst-nctui
          dunst
          dunst-toggle-mode
          gnome-icon-theme
          libnotify
        ];
      };

      xdg.dataFile."dbus-1/services/org.knopwob.dunst.service".source =
        "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

      xdg.configFile = {
        "dunst/assets/notification.flac".source = ./assets/notification.flac;
        "dunst/dunstrc" = {
          source = if preferDark then
            catppuccin-dunst-dark-theme-path
          else
            catppuccin-dunst-light-theme-path;
          force = true;
        };
        "dunst/dunstrc-light".source = catppuccin-dunst-light-theme-path;
        "dunst/dunstrc-dark".source = catppuccin-dunst-dark-theme-path;
        "dunst-nctui/config.toml".source = ./dotfiles/dunst-nctui.toml;
      };

      systemd.user.services.dunst = lib._custom.mkWaylandService {
        Unit = {
          Description = "Lightweight and customizable notification daemon";
          Documentation = "https://github.com/dunst-project/dunst";
        };
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          ExecStart = "${pkgs.dunst}/bin/dunst";
        };
      };
    };
  };
}
