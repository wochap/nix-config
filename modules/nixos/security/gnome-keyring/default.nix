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

    security.pam.services = {
      login.enableGnomeKeyring = true;

      # unlock gnome-keyring with password entered in greetd
      greetd.enableGnomeKeyring = config._custom.desktop.greetd.enable;
    };
    _custom.security.pam.enablePamSystemdLoadkey = true;
    _custom.desktop.greetd.enablePamSystemdLoadkey =
      config._custom.desktop.greetd.enable;

    xdg.portal.config = {
      common."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      Hyprland."org.freedesktop.impl.portal.Secret" =
        lib.mkIf config._custom.desktop.hyprland.enable [ "gnome-keyring" ];
    };

    # TODO: use services.gnome.gcr-ssh-agent.enable
    # this sets SSH_AUTH_SOCK
    systemd = {
      # NOTE: only nixpkgs-unstable.gcr_4 outputs service and socket file
      packages = [ pkgs.nixpkgs-unstable.gcr_4 ];
      user.services.gcr-ssh-agent.wantedBy = [ "default.target" ];
      user.sockets.gcr-ssh-agent.wantedBy = [ "sockets.target" ];
    };

    _custom.hm = {
      # GnuPG integration
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry
      '';

      # disable kwallet
      xdg.configFile."kwalletrc".source = ./dotfiles/kwalletrc;

      systemd.user.services.gnome-keyring = {
        Unit = {
          Description = "GNOME Keyring";
          PartOf = [ "graphical-session-pre.target" ];
        };
        Service = {
          # Use wrapped gnome-keyring-daemon with cap_ipc_lock=ep
          ExecStart =
            "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets";
          Restart = "on-abort";
        };
        Install.WantedBy = [ "graphical-session-pre.target" ];
      };
    };
  };
}
