{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.gnome-keyring;
  gnomeKeyringInitStr = ''
    eval $(gnome-keyring-daemon --start 2> /dev/null)
  '';
in {
  options._custom.services.gnome-keyring = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;

    # NOTE: unlock gnome-keyring with greetd
    security.pam.services.greetd.enableGnomeKeyring = true;

    _custom.hm = {
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry
      '';

      services.gnome-keyring = {
        enable = true;
        components = [ "pkcs11" "secrets" "ssh" ];
      };

      programs.bash.initExtra = gnomeKeyringInitStr;
      programs.zsh.initExtra = gnomeKeyringInitStr;
    };
  };
}
