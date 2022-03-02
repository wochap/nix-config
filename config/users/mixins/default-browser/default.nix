{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../packages { pkgs = pkgs; lib = lib; };
  http-url-handler = pkgs.makeDesktopItem {
    name = "http-url-handler";
    desktopName = "HTTP URL handler";
    comment = "Open an HTTP/HTTPS URL with a particular browser";
    exec = "/etc/scripts/open_url.sh %u";
    type = "Application";
    terminal = "false";
    extraEntries = ''
      TryExec=/etc/scripts/open_url.sh
      X-MultipleArgs=false
      NoDisplay=true
      MimeType=x-scheme-handler/http;x-scheme-handler/https
    '';
  };
in
{
  config = {
    environment = {
      etc = {
        "scripts/open_url.sh" = {
          source = ./scripts/open_url.sh;
          mode = "0755";
        };
      };
      systemPackages = [
        http-url-handler
      ];
    };

    home-manager.users.${userName} = {
      xdg.mimeApps = {
        defaultApplications = {
          "default-web-browser" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/chrome" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/http" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/https" = [ "http-url-handler.desktop" ];
          "x-scheme-handler/unknown" = [ "http-url-handler.desktop" ];
        };
        # associations.added = {
        #   "text/html" = [ "http-url-handler.desktop" ];
        #   "x-scheme-handler/http" = [ "http-url-handler.desktop" ];
        #   "x-scheme-handler/https" = [ "http-url-handler.desktop" ];
        # };
      };
    };
  };
}
