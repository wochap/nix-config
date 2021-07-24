{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../packages { pkgs = pkgs; };
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
      sessionVariables = {
        BROWSER = "http-url-handler.desktop";
      };
      systemPackages = [
        localPkgs.http-url-handler
      ];
    };
  };
}
