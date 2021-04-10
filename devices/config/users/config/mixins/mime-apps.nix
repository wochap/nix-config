{ config, pkgs, lib, ... }:

{
  config = {
    home-manager.users.gean = {
      # Control default apps
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
          "image/jpeg" = [ "org.gnome.eog.desktop" ];
          "image/png" = [ "org.gnome.eog.desktop" ];
          "image/svg+xml" = [ "org.gnome.eog.desktop" ];
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          "message/rfc822" = [ "userapp-Thunderbird-LAA0Y0.desktop" ];
          "text/html" = [ "google-chrome.desktop" ];
          "video/mp4" = [ "mpv.desktop" ];
          "video/x-matroska" = [ "mpv.desktop" ];
          "x-scheme-handler/http" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/https" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/mailto" = [ "exo-mail-reader.desktop" ];
          "x-scheme-handler/postman" = [ "Postman.desktop" ];
          "x-scheme-handler/webcal" = [ "google-chrome.desktop" ];
        };
        associations.added = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
          "image/jpeg" = [ "org.gnome.eog.desktop" "org.nomacs.ImageLounge.desktop" ];
          "image/png" = [ "org.gnome.eog.desktop" "org.nomacs.ImageLounge.desktop" ];
          "image/svg+xml" = [ "org.gnome.eog.desktop" ];
          "inode/directory" = [ "thunar.desktop" "org.gnome.Nautilus.desktop" ];
          "message/rfc822" = [ "userapp-Thunderbird-LAA0Y0.desktop" ];
          "text/html" = [ "http-url-handler.desktop" "firefox.desktop" "google-chrome.desktop" "brave-browser.desktop" ];
          "video/mp4" = [ "mpv.desktop" ];
          "video/x-matroska" = [ "mpv.desktop" ];
          "x-scheme-handler/http" = [ "http-url-handler.desktop" "firefox.desktop" "google-chrome.desktop" "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "http-url-handler.desktop" "firefox.desktop" "google-chrome.desktop" "brave-browser.desktop" ];
          "x-scheme-handler/mailto" = [ "userapp-Thunderbird-LAA0Y0.desktop" "userapp-Evolution-S7FTY0.desktop" ];
          "x-scheme-handler/postman" = [ "Postman.desktop" ];
        };
      };
    };
  };
}
