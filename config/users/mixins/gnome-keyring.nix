{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    # GUI for gnome-keyring
    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;

    # Fix gnome-keyring when lightdm is enablid
    security.pam.services.login.enableGnomeKeyring = true;

    home-manager.users.${userName} = {
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gtk2}/bin/pinentry
      '';

      # TODO: move it to shell init?
      xsession.profileExtra = ''
        systemctl --user import-environment

        eval $(${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
        export SSH_AUTH_SOCK
      '';
    };
  };
}
