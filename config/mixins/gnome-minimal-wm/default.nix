{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../packages { pkgs = pkgs; lib = lib; };
in
{
  config = {
    environment = {
      etc = {
        "scripts/restart_goa_daemon.sh" = {
          source = ./scripts/restart_goa_daemon.sh;
          mode = "0755";
        };
      };
    };

    # Required for some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    services = {
      # Required for gnome `Online Accounts`, Calendar and Geary
      gnome = {
        evolution-data-server.enable = true;
        gnome-online-accounts.enable = true;
        gnome-keyring.enable = true;
      };

      # Required by pinentry-gnome3
      dbus = {
        enable = true;
        packages = [ pkgs.gcr ];
      };
    };

    # Fix gnome-keyring when sddm is enabled
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
