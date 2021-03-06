{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; };
in
{
  config = {
    environment = {
      etc = {
        "restart_goa_daemon.sh" = {
          source = ../scripts/restart_goa_daemon.sh;
          mode = "0755";
        };
      };
      systemPackages = with pkgs; [
        # APPS
        # gnome3.bijiben
        gnome3.cheese # test webcam
        gnome3.eog # image viewer
        gnome3.evolution # email/calendar client
        gnome3.file-roller # archive manager
        gnome3.geary # email client
        gnome3.gnome-calculator
        gnome3.gnome-calendar
        gnome3.gnome-clocks
        gnome3.gnome-control-center # add google account for gnome apps
        gnome3.gnome-font-viewer
        gnome3.gnome-sound-recorder # test microphone
        gnome3.gnome-system-monitor
        gnome3.gnome-todo
        gnome3.nautilus
        gnome3.pomodoro
        gnome3.seahorse # manage GnomeKeyring
        gtimelog

        # Themes
        gnome3.adwaita-icon-theme

        # Themes settings
        gnome3.gsettings-desktop-schemas
        gtk-engine-murrine
        gtk_engines
        lxappearance
      ] ++ [
        localPkgs.whitesur-dark-icons
        localPkgs.whitesur-dark-theme
      ];
    };

    # Required for some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    services = {
      # Required for gnome `Online Accounts`, Calendar and Geary
      gnome3 = {
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
