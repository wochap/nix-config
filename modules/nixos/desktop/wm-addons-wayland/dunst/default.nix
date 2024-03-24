{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.dunst;
  inherit (config._custom.globals) themeColors;
  settings = builtins.fromTOML
    (builtins.replaceStrings [ "=yes" "=no" ] [ "=true" "=false" ]
      (builtins.readFile ./dotfiles/dunstrc));
  toDunstIni = with lib;
    generators.toINI {
      mkKeyValue = key: value:
        let
          value' = if isBool value then
            (lib.home-manager.booleans.yesNo value)
          else if isString value then
            ''"${value}"''
          else
            toString value;
        in "${key}=${value'}";
    };

  dunst-toggle-mode = pkgs.writeScriptBin "dunst-toggle-mode"
    (builtins.readFile ./scripts/dunst-toggle-mode.sh);
  dunst-play-notification-sound =
    pkgs.writeScriptBin "dunst-play-notification-sound"
    (builtins.readFile ./scripts/dunst-play-notification-sound.sh);
in {
  options._custom.desktop.dunst.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ reversal-icon-theme ];

    _custom.hm = {
      home = {
        packages = with pkgs; [
          _custom.dunst-nctui
          dunst
          dunst-play-notification-sound
          dunst-toggle-mode
          gnome-icon-theme
          libnotify
        ];
      };

      xdg.dataFile."dbus-1/services/org.knopwob.dunst.service".source =
        "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

      xdg.configFile = {
        "dunst/assets/notification.flac".source = ./assets/notification.flac;
        "dunst/dunstrc".text = toDunstIni (lib.recursiveUpdate settings {
          global = {
            inherit (themeColors) background foreground;
            frame_color = themeColors.selection;
            format =
              "<b>%s</b> <span color='${themeColors.comment}'>(%a)</span>\\n%b";
          };
          urgency_critical = { frame_color = themeColors.red; };
        });
      };

      systemd.user.services.dunst = lib._custom.mkWaylandService {
        Unit = {
          Description = "Lightweight and customizable notification daemon";
          Documentation = "https://github.com/dunst-project/dunst";
        };
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          PassEnvironment =
            [ "WAYLAND_DISPLAY" "XCURSOR_THEME" "XCURSOR_SIZE" "PATH" "HOME" ];
          ExecStart = "${pkgs.dunst}/bin/dunst";
        };
      };
    };
  };
}
