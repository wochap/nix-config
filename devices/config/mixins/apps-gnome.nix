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
        # gnome.bijiben
        gnome.cheese # test webcam
        gnome.eog # image viewer
        evolution # email/calendar client
        gnome.file-roller # archive manager
        gnome.geary # email client
        gnome.gnome-calculator
        gnome.gnome-calendar
        gnome.gnome-clocks
        gnome.gnome-control-center # add google account for gnome apps
        gnome.gnome-font-viewer
        gnome.gnome-sound-recorder # test microphone
        gnome.gnome-system-monitor
        prevstable.gnome3.gnome-todo
        gnome.nautilus
        gnome.pomodoro
        gnome.seahorse # manage GnomeKeyring
        gtimelog

        # Themes
        gnome.adwaita-icon-theme

        # Themes settings
        gnome.gsettings-desktop-schemas
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
