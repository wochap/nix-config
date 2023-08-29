{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  http-url-handler = pkgs.unstable.makeDesktopItem {
    name = "http-url-handler";
    desktopName = "HTTP URL handler";
    comment = "Open an HTTP/HTTPS URL with a particular browser";
    exec = "/etc/scripts/open_url.sh %u";
    type = "Application";
    terminal = false;
    tryExec = "/etc/scripts/open_url.sh";
    noDisplay = true;
    mimeTypes = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
    extraConfig = { X-MultipleArgs = "false"; };
  };
in {
  config = {
    environment = {
      etc = {
        "scripts/open_url.sh" = {
          source = ./scripts/open_url.sh;
          mode = "0755";
        };
      };
      systemPackages = [ http-url-handler ];
    };

    home-manager.users.${userName} = {
      xdg.mimeApps = {
        defaultApplications = {
          "default-web-browser" = [ "google-chrome.desktop" ];
          "x-scheme-handler/chrome" = [ "google-chrome.desktop" ];
          "x-scheme-handler/http" = [ "google-chrome.desktop" ];
          "x-scheme-handler/https" = [ "google-chrome.desktop" ];
          "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
        };
      };
    };
  };
}
