{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;

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
    '';
  };
in {
  config = {
    environment = {
      systemPackages = with pkgs; [ configure-gtk ];

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
      };
    };
  };
}
