{ config, pkgs, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../packages { pkgs = pkgs; };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # Themes
        tela-icon-theme
        orchis
        numix-icon-theme-circle
        gnome.adwaita-icon-theme
        dracula-theme
        adementary-theme

        # Themes settings
        gtk3
        gnome.gsettings-desktop-schemas
        gtk-engine-murrine
        gnome-themes-extra
        gtk_engines
        lxappearance
      ] ++ [
        localPkgs.dracula-icons
        localPkgs.whitesur-dark-icons
        localPkgs.whitesur-dark-theme
      ];
      variables = {
        # Hide dbus errors
        "NO_AT_BRIDGE" = "1";
      };
    };

    home-manager.users.${userName} = {
      gtk = {
        enable = true;
        iconTheme = {
          name = "Tela";
          package = pkgs.tela-icon-theme;
        };
        theme = {
          name = "Orchis-dark";
          package = pkgs.orchis;
        };
        gtk3.extraConfig = {
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
      };
    };
  };
}
