{ config, pkgs, lib, ... }:

let
  theme = config._theme;

  # TODO: add run-or-raise cli
  # TODO: add focus cli

  # HACK: fix portals
  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of wayland wm config
  # see: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  dbus-wayland-wm-environment = pkgs.writeTextFile {
    name = "dbus-wayland-wm-environment";
    destination = "/bin/dbus-wayland-wm-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment SEATD_SOCK DISPLAY WAYLAND _DISPLAY XDG_CURRENT_DESKTOP=river
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

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
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS

      gnome_schema="org.gnome.desktop.interface"

      gsettings set $gnome_schema cursor-theme capitaine-cursors &
      gsettings set $gnome_schema cursor-size 32 &

      # import gtk settings to gsettings
      config="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
      if [ ! -f "$config" ]; then exit 1; fi

      gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
      gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
      gsettings set "$gnome_schema" icon-theme "$icon_theme"
      gsettings set "$gnome_schema" font-name "$font_name"
    '';
  };
in { inherit dbus-wayland-wm-environment configure-gtk; }
