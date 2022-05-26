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

    # Required by some apps (gtk3 applications, firefox)
    # Fix https://github.com/NixOS/nixpkgs/issues/30866
    programs.dconf.enable = true;

    # Required by gnome file managers
    programs.file-roller.enable = true;

    services = {
      gvfs.package = lib.mkForce pkgs.gnome3.gvfs;

      gnome = {
        # Required by gnome `Online Accounts`, Calendar and Geary
        evolution-data-server.enable = true;
        gnome-online-accounts.enable = true;

        # Required by nautilus
        tracker-miners.enable = true;
        tracker.enable = true;

        # On minimal wm, it doesn't do anything
        gnome-settings-daemon.enable = true;
      };
    };

  };
}
