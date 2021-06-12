{ config, pkgs, ... }:

let
  localPkgs = import ../../../packages { pkgs = pkgs; };
in
{
  config = {
    home-manager.users.gean = {
      gtk = {
        enable = true;
        iconTheme = {
          name = "WhiteSur-dark";
          package = localPkgs.whitesur-dark-icons;
        };
        theme = {
          name = "WhiteSur-dark";
          package = localPkgs.whitesur-dark-theme;
        };
        font = {
          name = "Roboto 9";
          package = pkgs.roboto;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-button-images = 1;
          gtk-cursor-theme-name = "bigsur-cursors";
          gtk-cursor-theme-size = 0;
          gtk-decoration-layout = "";
          gtk-enable-animations = true;
          gtk-enable-event-sounds = 1;
          gtk-enable-input-feedback-sounds = 1;
          gtk-menu-images = 1;
          gtk-primary-button-warps-slider = true;
          gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
          gtk-toolbar-style = "GTK_TOOLBAR_BOTH_HORIZ";
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-xft-rgba = "rgb";
        };
        gtk3.bookmarks = [
          "file:///home/gean/Documents"
          "file:///home/gean/Downloads"
          "file:///home/gean/Pictures"
          "file:///home/gean/Projects"
          "file:///home/gean/Recordings"
          "file:///home/gean/Videos"
        ];
        gtk2.extraConfig = ''
          gtk-button-images = 1
          gtk-cursor-theme-name = "bigsur-cursors"
          gtk-cursor-theme-size = 0
          gtk-enable-event-sounds = 1
          gtk-enable-input-feedback-sounds = 1
          gtk-menu-images = 1
          gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
          gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
          gtk-xft-antialias = 1
          gtk-xft-hinting = 1
          gtk-xft-hintstyle = "hintfull"
          gtk-xft-rgba = "rgb"
        '';
      };
    };
  };
}
