{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../packages {
    pkgs = pkgs;
    lib = lib;
  };
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
    extraConfig = {
      X-MultipleArgs = "false";
    };
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
