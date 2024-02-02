{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.gtk;
  inherit (config._custom) globals;
  inherit (config._custom.globals) userName configDirectory displayServer;
  isWayland = displayServer == "wayland";
  inherit (lib._custom) relativeSymlink;
  extraCss = ''
    @import url("file://${relativeSymlink configDirectory ./dotfiles/gtk.css}");
    @import url("file://${
      relativeSymlink configDirectory ./dotfiles/catppuccin-mocha.css
    }");
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
      home.sessionVariables = lib.mkMerge [
        {
          # Hide dbus errors in GTK apps?
          NO_AT_BRIDGE = "1";

          # https://wiki.gnome.org/Initiatives/CSD
          GTK_CSD = "1";
        }
        (lib.mkIf isWayland {
          # Force GTK to use wayland
          GDK_BACKEND = "wayland,x11";

          CLUTTER_BACKEND = "wayland";
        })
      ];

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
