{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.gtk;
  inherit (config._custom) globals;
  inherit (config._custom.globals) userName configDirectory;
  inherit (lib._custom) relativeSymlink;
  extraCss = lib.concatLines [
    ''
      /* Palette */
      @import url("file:///home/${userName}/.config/theme-colors.css");
      @import url("file://${./dotfiles/catppuccin.css}");
    ''
    (lib.optionalString (!cfg.enableCsd) ''
      @import url("file://${
        relativeSymlink configDirectory ./dotfiles/gtk-remove-csd.css
      }");
    '')
  ];

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
    gsettings set $gnome_schema cursor-size ${toString (globals.cursor.size)} &

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
  options._custom.desktop.gtk = {
    enable = lib.mkEnableOption { };
    enableCsd = lib.mkEnableOption { };
    enableTheme = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        awf # widget factory
        dconf-editor
        configure-gtk

        # gtk deps
        glib # for gsettings program
        gtk3.out # for gtk-launch program
        gsettings-desktop-schemas

        # gtk themes
        globals.gtkTheme.package
        adwaita-icon-theme
        gnome-themes-extra
        hicolor-icon-theme
        numix-icon-theme-circle
        numix-icon-theme-square
        tela-icon-theme
        xfce.xfce4-icon-theme
        reversal-icon-theme
      ];

      # NOTE: can't move it to home-manager because of a conflict
      sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };

    # Enable GTK applications to load SVG icons
    programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    # Required by some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    _custom.hm = {
      home.sessionVariables = lib.mkMerge [
        {
          # Hide dbus errors in GTK apps?
          NO_AT_BRIDGE = "1";
        }
        (lib.mkIf cfg.enableCsd {
          # https://wiki.gnome.org/Initiatives/CSD
          GTK_CSD = "1";
        })
      ];

      # Prevent home-manager service to fail
      # https://discourse.nixos.org/t/way-to-automatically-override-home-manager-collisions/33038/3
      xdg.configFile = {
        "gtk-4.0/gtk.css".force = true;
        "gtk-4.0/settings.ini".force = true;
        "gtk-3.0/gtk.css".force = true;
        "gtk-3.0/settings.ini".force = true;
      };

      dconf.settings = {
        # Open GTK inspector with Ctrl + Shift + D
        # GTK_DEBUG=interactive <app>
        "org/gtk/Settings/Debug".enable-inspector-keybinding = true;

        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      };

      gtk = {
        enable = cfg.enableTheme;
        font = {
          name = globals.fonts.sans;
          inherit (globals.fonts) size;
        };
        iconTheme = { inherit (globals.gtkIconTheme) name package; };
        theme = { inherit (globals.gtkTheme) name package; };

        gtk3 = {
          inherit extraCss;
          extraConfig = {
            gtk-application-prefer-dark-theme = true;
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintfull";
          };
          bookmarks = [
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
        };
        gtk4.extraCss = extraCss;
      };
    };
  };
}
