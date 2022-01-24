{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../packages { pkgs = pkgs; lib = lib; };
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
          gnome.gsettings-desktop-schemas
          gtk-engine-murrine
          gtk_engines
        ] ++ [
          localPkgs.dracula-icons
        ];
      variables = {
        # Hide dbus errors
        "NO_AT_BRIDGE" = "1";
      };
      sessionVariables = {
        # https://wiki.gnome.org/Initiatives/CSD
        GTK_CSD = "1";

        XDG_DATA_DIRS = [
          "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"
        ];
      };
    };

    home-manager.users.${userName} = {
      gtk = {
        enable = true;
        iconTheme = {
          name = "Tela-dark";
          package = pkgs.tela-icon-theme;
        };
        theme = {
          name = "Orchis-dark-compact";
          package = pkgs.orchis;
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
          "file:///home/${userName}/Documents"
          "file:///home/${userName}/Downloads"
          "file:///home/${userName}/Pictures"
          "file:///home/${userName}/Projects"
          "file:///home/${userName}/Recordings"
          "file:///home/${userName}/Videos"
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
