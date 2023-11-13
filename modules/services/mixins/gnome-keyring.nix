{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.gnome-keyring;
  userName = config._userName;
in {
  options._custom.services.gnome-keyring = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    # GUI for gnome-keyring
    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;

    # Fix gnome-keyring when lightdm is enabled
    security.pam.services.login.enableGnomeKeyring = true;

    # Fix gnome-keyring when greetd is enabled
    security.pam.services.greetd.enableGnomeKeyring = true;

    environment.loginShellInit = ''
      eval $(${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
      export SSH_AUTH_SOCK
    '';

    home-manager.users.${userName} = {
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry
      '';
    };

  };
}