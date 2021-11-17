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
        gnome.adwaita-icon-theme
        dracula-theme
        adementary-theme

        # Themes settings
        gnome.gsettings-desktop-schemas
        gtk-engine-murrine
        gtk_engines
        lxappearance
      ] ++ [
        localPkgs.dracula-icons
        localPkgs.whitesur-dark-icons
        localPkgs.whitesur-dark-theme
      ];
    };

    home-manager.users.${userName} = {
      gtk = {
        enable = true;
        iconTheme = {
          name = "Numix Circle";
          package = pkgs.numix-icon-theme;
        };
        theme = {
          name = "Arc-Dark";
          package = pkgs.arc-theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-cursor-theme-size = 0;
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
