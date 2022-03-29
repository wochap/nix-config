{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  pinentryFlavor = "gtk2";
in {
  config = {
    # Required by pinentry-gnome3
    services.dbus.packages = with pkgs; [ gcr ];

    environment.systemPackages = with pkgs; [ pinentry-gnome gcr ];

    home-manager.users.${userName} = {

      # Test with gtk2
      home.file = {
        ".gnupg/gpg-agent.conf".text = ''
          default-cache-ttl 34560000
          max-cache-ttl 34560000

          pinentry-program ${pkgs.pinentry.${pinentryFlavor}}/bin/pinentry
        '';
        # pinentry-program ${pkgs.pinentry-gtk2}/bin/pinentry
        # pinentry-program ${pkgs.pinentry}/bin/pinentry
        # pinentry-program ${pkgs.pinentry-gnome}/bin/pinentry
        # pinentry-program ${pkgs.pinentry-gnome}/bin/pinentry-gnome3
      };

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = false;
        pinentryFlavor = "gtk2";
        enableExtraSocket = true;
        enableScDaemon = false;
        enableSshSupport = false;
      };
    };

  };
}
