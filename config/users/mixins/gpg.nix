{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    # Required by pinentry-gnome3
    services.dbus = {
      enable = true;
      packages = [ pkgs.gcr ];
    };

    home-manager.users.${userName} = {

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        pinentryFlavor = "gnome3";
        enableSshSupport = false;
      };
    };
  };
}
