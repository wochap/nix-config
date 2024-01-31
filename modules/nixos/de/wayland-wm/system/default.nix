{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom) globals;
  userName = config._userName;

  hyprpicker = pkgs.callPackage "${inputs.hyprpicker}/nix/default.nix" { };

  # Apply GTK theme
  # currently, there is some friction between Wayland and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;

    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      #!/usr/bin/env bash

      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS

      gnome_schema="org.gnome.desktop.interface"

      gsettings set $gnome_schema cursor-theme ${globals.cursor.name} &
      gsettings set $gnome_schema cursor-size ${toString globals.cursor.size} &

      # import gtk settings to gsettings
      config="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
      if [ ! -f "$config" ]; then exit 1; fi

      gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
      gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
      gsettings set "$gnome_schema" icon-theme "$icon_theme"
      gsettings set "$gnome_schema" font-name "$font_name"

      # remove GTK window buttons
      gsettings set org.gnome.desktop.wm.preferences button-layout ""
    '';
  };

  # HACK: fix portals
  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of wayland wm config
  # see: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # SWAYSOCK, /etc/sway/config.d/nixos.conf has it
  restart-pipewire-and-portal-services = pkgs.writeTextFile {
    name = "restart-pipewire-and-portal-services";
    destination = "/bin/restart-pipewire-and-portal-services";
    executable = true;

    text = ''
      #!/usr/bin/env bash

      wait_for_service() {
        while [[ $(systemctl --user is-active "$1") != "active" ]]; do
          sleep 0.1
        done
      }

      export XDG_CURRENT_DESKTOP=sway
      dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      systemctl --user stop pipewire pipewire-pulse wireplumber xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
      systemctl --user start xdg-desktop-portal-wlr xdg-desktop-portal-gtk
      wait_for_service xdg-desktop-portal-wlr
      wait_for_service xdg-desktop-portal-gtk
      systemctl --user start xdg-desktop-portal
      wait_for_service xdg-desktop-portal
      systemctl --user start pipewire pipewire-pulse wireplumber
    '';
  };

  play-notification-sound = pkgs.writeTextFile {
    name = "play-notification-sound";
    destination = "/bin/play-notification-sound";
    executable = true;
    text = builtins.readFile ./scripts/play-notification-sound.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        restart-pipewire-and-portal-services
        configure-gtk
        hyprpicker # color picker
        swaylock-effects # lockscreen

        slurp # screenshoot utility
        grim # screenshoot utility
        wf-recorder # screen recorder utility
        wl-screenrec # screen recorder utility (faster)

        # clipboard manager
        cliphist
        unstable.wl-clip-persist
        wl-clipboard
      ];

      etc = {
        "scripts/system/sway-lock.sh" = {
          source = ./scripts/sway-lock.sh;
          mode = "0755";
        };
        "scripts/system/clipboard-manager.sh" = {
          source = ./scripts/clipboard-manager.sh;
          mode = "0755";
        };
        "scripts/system/color-picker.sh" = {
          source = ./scripts/color-picker.sh;
          mode = "0755";
        };
        "scripts/system/takeshot.sh" = {
          source = ./scripts/takeshot.sh;
          mode = "0755";
        };
        "scripts/system/recorder.sh" = {
          source = ./scripts/recorder.sh;
          mode = "0755";
        };
        "scripts/system/battery-notification.sh" = {
          source = ./scripts/battery-notification.sh;
          mode = "0755";
        };
      };
    };

    # HACK: necessary for swaylock to unlock
    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };

    home-manager.users.${userName} = {
      home.packages = with pkgs; [ play-notification-sound ];
      xdg.dataFile."assets/notification.flac".source =
        ./assets/notification.flac;

      # swayidle
      services.swayidle = {
        enable = true;
        systemdTarget = "graphical-session.target";
        events = [
          {
            event = "before-sleep";
            command = "bash /etc/scripts/system/sway-lock.sh";
          }
          {
            event = "lock";
            command = "bash /etc/scripts/system/sway-lock.sh";
          }
        ];
        timeouts = [{
          timeout = 180;
          command = "bash /etc/scripts/system/sway-lock.sh";
        }];
      };

      # fake a tray to let apps start
      # https://github.com/nix-community/home-manager/issues/2064
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      systemd.user.services = let
        mkService = lib.recursiveUpdate {
          Unit.PartOf = [ "graphical-session.target" ];
          Unit.After = [ "graphical-session.target" ];
          Install.WantedBy = [ "graphical-session.target" ];
        };
      in {
        swayidle = {
          Service = {
            Environment = lib.mkForce "";
            PassEnvironment = "PATH";
          };
        };

        cliphist = mkService {
          Unit.Description = "Wayland clipboard manager";
          Unit.Documentation = "https://github.com/sentriz/cliphist";
          Service = {
            PassEnvironment = "PATH";
            ExecStart = "/etc/scripts/system/clipboard-manager.sh --start";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        };

        battery-notification = mkService {
          Unit.Description =
            "A script that shows warning messages to the user when the battery is almost empty.";
          Unit.Documentation = "https://github.com/rjekker/i3-battery-popup";
          Service = {
            PassEnvironment = [ "PATH" "DISPLAY" ];
            ExecStart =
              "/etc/scripts/system/battery-notification.sh -t 5s -L 15 -l 5 -n -i battery -D";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        };
      };
    };

  };
}
