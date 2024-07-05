{ config, pkgs, lib, ... }:

let cfg = config._custom.security.gnome-keyring;
in {
  options._custom.security.gnome-keyring.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libgnome-keyring
      libsecret # secret-tool
    ];

    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;

    security.pam.services.login.enableGnomeKeyring = true;

    # Unlock gnome keyring with password entered in greetd
    security.pam.services.greetd.enableGnomeKeyring =
      config._custom.desktop.greetd.enable;

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
          PartOf = [ "graphical-session-pre.target" ];
        };
        Service = {
          # Use wrapped gnome-keyring-daemon with cap_ipc_lock=ep
          ExecStart =
            "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets,ssh,pkcs11";
          Restart = "on-abort";
        };
        Install.WantedBy = [ "graphical-session-pre.target" ];
      };
    };
  };
}
