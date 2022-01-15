{ config, pkgs, lib, ... }:

# NOTE: this file requires xfce-minimal-wm/defaul.nix
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

    # Required for gnome file managers
    programs.file-roller.enable = true;

    # manage GnomeKeyring
    programs.seahorse.enable = true;

    programs.evolution.enable = true;

    services = {
      gnome = {
        # Required for gnome `Online Accounts`, Calendar and Geary
        evolution-data-server.enable = true;
        gnome-online-accounts.enable = true;
        gnome-keyring.enable = true;

        # Required by nautilus
        tracker-miners.enable = true;
        tracker.enable = true;
      };
    };

    # Fix gnome-keyring when sddm is enabled
    security.pam.services.sddm.enableGnomeKeyring = true;

    services.gnome.gnome-settings-daemon.enable = true;
  };
}
