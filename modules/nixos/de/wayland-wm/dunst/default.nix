{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  settings = builtins.fromTOML
    (builtins.replaceStrings [ "=yes" "=no" ] [ "=true" "=false" ]
      (builtins.readFile ./dotfiles/dunstrc));
  toDunstIni = with lib;
    generators.toINI {
      mkKeyValue = key: value:
        let
          value' = if isBool value then
            (hmConfig.lib.booleans.yesNo value)
          else if isString value then
            ''"${value}"''
          else
            toString value;
        in "${key}=${value'}";
    };

  dunst-toggle-mode = pkgs.writeTextFile {
    name = "dunst-toggle-mode";
    destination = "/bin/dunst-toggle-mode";
    executable = true;
    text = builtins.readFile ./scripts/dunst-toggle-mode.sh;
  };
  dunst-play-notification-sound = pkgs.writeTextFile {
    name = "dunst-play-notification-sound";
    destination = "/bin/dunst-play-notification-sound";
    executable = true;
    text = builtins.readFile ./scripts/dunst-play-notification-sound.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    # so it propagates to:
    # /run/current-system/sw/share/icons/Numix-Square
    environment.systemPackages = with pkgs; [ numix-icon-theme-square ];

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
              "<b>%s</b> <span color='${themeColors.cyan}'>(%a)</span>\\n%b";
          };
          urgency_critical = { frame_color = themeColors.red; };
        });
      };

      systemd.user.services.dunst = {
        Unit = {
          Description = "Lightweight and customizable notification daemon";
          Documentation = "https://github.com/dunst-project/dunst";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          PassEnvironment =
            [ "WAYLAND_DISPLAY" "XCURSOR_THEME" "XCURSOR_SIZE" "PATH" "HOME" ];
          ExecStart = "${pkgs.dunst}/bin/dunst";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
