{ config, pkgs, lib, ... }:

let cfg = config._custom.security.gnome-keyring;
in {
  options._custom.security.gnome-keyring.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnome.libgnome-keyring ];

    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;

    # Automatic unlocking keyring without automatic login
    security.pam.services.greetd.enableGnomeKeyring = true;

    xdg.portal.config.common."org.freedesktop.impl.portal.Secret" =
      [ "gnome-keyring" ];

    _custom.hm = {
      # GnuPG integration
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry
      '';

      # SSH integration
      home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

      systemd.user.services.gnome-keyring = {
        Unit = {
          Description = "GNOME Keyring";
          PartOf = [ "default.target" ];
        };
        Service = {
          # Use wrapped gnome-keyring-daemon with cap_ipc_lock=ep
          ExecStart =
            "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets,ssh,pkcs11";
          Restart = "on-abort";
        };
        Install = { WantedBy = [ "default.target" ]; };
      };
    };
  };
}
