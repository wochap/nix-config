{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    # Required by pinentry-gnome3
    services.dbus.packages = with pkgs; [ gcr ];

    environment.systemPackages = with pkgs; [ pinentry-gnome gcr ];

    home-manager.users.${userName} = {

      # home.file = {
      #   ".gnupg/gpg-agent.conf".text = ''
      #     default-cache-ttl 1800
      #     pinentry-program ${pkgs.pinentry-gnome}/bin/pinentry-gnome3
      #   '';
      #   # pinentry-program ${pkgs.pinentry-gnome}/bin/pinentry
      # };

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        pinentryFlavor = "gnome3";
        enableExtraSocket = true;
        enableScDaemon = false;
        enableSshSupport = false;
      };
    };

  };
}
