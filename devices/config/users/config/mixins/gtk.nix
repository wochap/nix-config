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
          name = "elementary";
          package = pkgs.pantheon.elementary-icon-theme;
        };
        theme = {
          name = "Adementary";
          package = pkgs.adementary-theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-button-images = 1;
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
          "file:///home/${userName}/Documents"
          "file:///home/${userName}/Downloads"
          "file:///home/${userName}/Pictures"
          "file:///home/${userName}/Projects"
          "file:///home/${userName}/Recordings"
          "file:///home/${userName}/Videos"
        ];
        gtk2.extraConfig = ''
          gtk-button-images = 1
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
