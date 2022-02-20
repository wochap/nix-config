{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  isWayland = config._displayServer == "wayland";
  localPkgs = import ../../packages {
    pkgs = pkgs;
    lib = lib;
  };
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
            "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"
          ];
        }
        (lib.mkIf isWayland {
          # Force GTK to use wayland
          # doesn't work with nvidia?
          GDK_BACKEND = "wayland";

          CLUTTER_BACKEND = "wayland";
        })
      ];
    };

    home-manager.users.${userName} = {
      home.file = { ".icons/Dracula".source = inputs.dracula-icons-theme; };

      gtk = {
        enable = true;

        # Theme
        font = { name = "JetBrainsMono Nerd Font"; };
        iconTheme = { name = "Dracula"; };
        theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
        };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-fallback-icon-theme = "gnome";

          # Hide minimize and maximize buttons
          gtk-decoration-layout = "menu:";

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
