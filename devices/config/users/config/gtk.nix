{ config, pkgs, ... }:

{
  config = {
    home-manager.users.gean = {
      gtk = {
        enable = true;
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
        theme = {
          name = "Arc-Dark";
          package = pkgs.arc-theme;
        };
        font = {
          name = "Work Sans 10";
          package = pkgs.work-sans;
        };
        # gtk3.extraCss
        gtk3.extraConfig = {
          gtk-cursor-theme-size = 0;
          gtk-toolbar-style = "GTK_TOOLBAR_BOTH_HORIZ";
          gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
          gtk-button-images = 0;
          gtk-menu-images = 0;
          gtk-enable-event-sounds = 1;
          gtk-enable-input-feedback-sounds = 1;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintslight";
          gtk-xft-rgba = "rgb";
          gtk-cursor-theme-name = "capitaine-cursors";
          gtk-application-prefer-dark-theme = 0;
        };
        # gtk3.bookmarks
        gtk2.extraConfig = ''
          gtk-cursor-theme-name = "capitaine-cursors"
          gtk-cursor-theme-size = 0
          gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
          gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
          gtk-button-images = 0
          gtk-menu-images = 0
          gtk-enable-event-sounds = 1
          gtk-enable-input-feedback-sounds = 1
          gtk-xft-antialias = 1
          gtk-xft-hinting = 1
          gtk-xft-hintstyle = "hintslight"
          gtk-xft-rgba = "rgb"
        '';
      };
    };
  };
}
