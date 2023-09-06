{ config, pkgs, inputs, lib, ... }:

let
  cfg = config._custom.wm.gtk;
  inherit (config._custom) globals;
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
in {
  options._custom.wm.gtk = {
    enable = lib.mkEnableOption "setup gtk theme and apps";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        glib # for gsettings program
        gtk3.out # for gtk-launch program

        awf # widget factory
        gnome.dconf-editor
        # _custom.nwg-look

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

      variables = {
        # Hide dbus errors in GTK apps?
        "NO_AT_BRIDGE" = "1";
      };

      sessionVariables = lib.mkMerge [
        {
          # https://wiki.gnome.org/Initiatives/CSD
          GTK_CSD = "1";

          XDG_DATA_DIRS = [
            "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
            "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
          ];
        }
        (lib.mkIf isWayland {
          # Force GTK to use wayland
          GDK_BACKEND = "wayland,x11";

          CLUTTER_BACKEND = "wayland";
        })
      ];
    };

    # Enable GTK applications to load SVG icons
    services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    # Required by some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Required by gnome file managers
    programs.file-roller.enable = true;

    programs.gnome-disks.enable = true;

    home-manager.users.${userName} = {
      # install gtk4 theme
      xdg.configFile = {
        "gtk-4.0/assets".source =
          "${globals.gtkTheme.package}/share/themes/${globals.gtkTheme.name}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source =
          "${globals.gtkTheme.package}/share/themes/${globals.gtkTheme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source =
          "${globals.gtkTheme.package}/share/themes/${globals.gtkTheme.name}/gtk-4.0/gtk-dark.css";
      };

      # TODO: move out
      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = { enable-inspector-keybinding = true; };
      };

      gtk = {
        enable = true;

        # Theme
        font = {
          name = globals.fonts.sans;
          inherit (globals.fonts) size;
        };
        iconTheme = { inherit (globals.gtkIconTheme) name package; };
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
          /** Some apps use titlebar class and some window */
          .titlebar,
          window {
            border-radius: 0;
            box-shadow: none;
          }

          /** also remove shaddows */
          decoration {
            box-shadow: none;
          }

          decoration:backdrop {
            box-shadow: none;
          }

          /* No (default) titlebar on wayland */
          headerbar.titlebar.default-decoration {
            background: transparent;
            padding: 0;
            margin: 0 0 -17px 0;
            border: 0;
            min-height: 0;
            font-size: 0;
            box-shadow: none;
          }

          /* rm -rf window shadows */
          window.csd,             /* gtk4? */
          window.csd decoration { /* gtk3 */
            box-shadow: none;
          }
        '';
      };
    };
  };
}
