{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.gtk;
  inherit (config._custom) globals;
  inherit (config._custom.globals) userName configDirectory displayServer;
  inherit (lib._custom) relativeSymlink;
  extraCss = ''
    @import url("file://${relativeSymlink configDirectory ./dotfiles/gtk.css}");
    @import url("file://${
      relativeSymlink configDirectory ./dotfiles/catppuccin-mocha.css
    }");
  '';

  # Apply GTK theme
  # currently, there is some friction between Wayland and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of config
  configure-gtk = let
    schema = pkgs.gsettings-desktop-schemas;
    datadir = "${schema}/share/gsettings-schemas/${schema.name}";
  in pkgs.writeScriptBin "configure-gtk" ''
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
in {
  options._custom.wm.gtk.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        glib # for gsettings program
        gtk3.out # for gtk-launch program

        awf # widget factory
        gnome.dconf-editor

        configure-gtk

        globals.gtkTheme.package
        gnome.adwaita-icon-theme
        gnome.gnome-themes-extra
        hicolor-icon-theme
        numix-icon-theme-circle # required by notifications
        tela-icon-theme
        xfce.xfce4-icon-theme

        # Themes settings
        gsettings-desktop-schemas
        # gtk-engine-murrine
        # gtk_engines
      ];

      # NOTE: can't move it to home-manager because of a conflict
      sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };

    # Enable GTK applications to load SVG icons
    services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    # Required by some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    _custom.hm = {
      home.sessionVariables = {
        # Hide dbus errors in GTK apps?
        NO_AT_BRIDGE = "1";

        # https://wiki.gnome.org/Initiatives/CSD
        GTK_CSD = "1";
      };

      dconf.settings = {
        # Open GTK inspector with Ctrl + Shift + D
        # GTK_DEBUG=interactive <app>
        "org/gtk/Settings/Debug" = { enable-inspector-keybinding = true; };

        "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
      };

      gtk = {
        enable = true;

        # Theme
        font = {
          name = globals.fonts.sans;
          inherit (globals.fonts) size;
        };
        iconTheme = { inherit (globals.gtkIconTheme) name package; };
        cursorTheme = { inherit (globals.cursor) package name size; };
        theme = { inherit (globals.gtkTheme) name package; };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          # gtk-fallback-icon-theme = "gnome";

          # Hide minimize and maximize buttons
          # gtk-decoration-layout = "menu:";

          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
        };
        gtk3.bookmarks = [
          "file:///home/${userName}/Downloads"
          "file:///home/${userName}/Pictures"
          "file:///home/${userName}/Videos"
          "file:///home/${userName}/nix-config"
          "file:///home/${userName}/Projects"
          "file:///home/${userName}/Projects/boc"
          "file:///home/${userName}/Videos/Recordings"
          "file:///home/${userName}/Pictures/Screenshots"
          "file:///home/${userName}/Sync"
        ];
        gtk3.extraCss = ''
          ${extraCss}
        '';
        gtk4.extraCss = ''
          ${extraCss}
        '';
      };
    };
  };
}
