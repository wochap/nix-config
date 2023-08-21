{ config, pkgs, lib, inputs, ... }:

let
  inherit (config._custom) globals;
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
  localPkgs = import ../../packages { inherit pkgs lib; };
in {
  config = {
    environment = {
      systemPackages = with pkgs;
        [
          awf # widget factory

          # Themes
          tela-icon-theme
          orchis
          numix-icon-theme-circle
          dracula-theme
          adementary-theme

          # Themes settings
          gsettings-desktop-schemas
          gtk-engine-murrine
          gtk_engines
        ] ++ [ localPkgs.dracula-icons ];
      variables = {
        # Hide dbus errors
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
          # doesn't work with nvidia?
          GDK_BACKEND = "wayland,x11";

          CLUTTER_BACKEND = "wayland";
        })
      ];
    };

    # Enable GTK applications to load SVG icons
    services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

    home-manager.users.${userName} = {
      home.file = {
        ".icons/Dracula".source = inputs.dracula-icons-theme;

        # Fix GTK 4 theme
        ".config/gtk-4.0/apps".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/apps";
        ".config/gtk-4.0/assets".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/assets";
        ".config/gtk-4.0/widgets".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/widgets";
        ".config/gtk-4.0/gtk.css".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/gtk.css";
        ".config/gtk-4.0/gtk-dark.css".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/gtk-dark.css";
        ".config/gtk-4.0/_apps.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/_apps.scss";
        ".config/gtk-4.0/_common.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/_common.scss";
        ".config/gtk-4.0/_drawing.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/_drawing.scss";
        ".config/gtk-4.0/gtk.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/gtk.scss";
        ".config/gtk-4.0/gtk-dark.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/gtk-dark.scss";
        ".config/gtk-4.0/_widgets.scss".source =
          "${inputs.dracula-gtk-theme}/gtk-4.0/_widgets.scss";
      };

      gtk = {
        enable = true;

        # Theme
        font = { name = globals.fonts.sans; };
        iconTheme = { name = "Dracula"; };
        theme = { inherit (globals.theme) name package; };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-fallback-icon-theme = "gnome";

          # Hide minimize and maximize buttons
          gtk-decoration-layout = "menu:";

          # Hide minimize, maximize, close buttons
          button-layout = "";

          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
        };
        gtk3.bookmarks = [
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
        '';
      };
    };
  };
}
