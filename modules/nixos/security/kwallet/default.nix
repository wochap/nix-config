{ config, pkgs, lib, ... }:

let cfg = config._custom.security.kwallet;
in {
  options._custom.security.kwallet.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.kwallet # provides helper service
      kdePackages.kwalletmanager # A GUI to manage your KWallet
      kdePackages.kwallet-pam # provides helper service
    ];

    xdg.portal.extraPortals = with pkgs; [ kdePackages.kwallet ];

    security.pam.services = {
      login = {
        kwallet = {
          enable = true;
          package = pkgs.kdePackages.kwallet-pam;
          forceRun = true;
        };
        rules.session.kwallet.settings.auto_start = true;
        # unlock KWallet using luks passphrase
        rules.auth.systemd_loadkey = {
          enable = false;
          order =
            config.security.pam.services.greetd.rules.auth.unix-early.order - 2;
          control = "optional";
          modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
        };
      };

      # TODO: kwallet doesn't unlock after login
      greetd = lib.mkIf config._custom.desktop.greetd.enable {
        kwallet = {
          enable = true;
          package = pkgs.kdePackages.kwallet-pam;
          forceRun = true;
        };
        rules.session.kwallet.settings.auto_start = true;
        # unlock KWallet using luks passphrase
        rules.auth.systemd_loadkey = {
          enable = false;
          order =
            config.security.pam.services.greetd.rules.auth.unix-early.order - 2;
          control = "optional";
          modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
        };
      };
    };

    # GnuPG integration
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
      enableSSHSupport = true;
    };

    # SSH integration
    programs.ssh.askPassword =
      "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

    xdg.portal.config = {
      common."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      Hyprland."org.freedesktop.impl.portal.Secret" =
        lib.mkIf config._custom.desktop.hyprland.enable [ "kwallet" ];
    };

    systemd.user.services."dbus-org.freedesktop.secrets.kwallet" = {
      description =
        "Allow KWallet to be D-Bus activated for the generic org.freedesktop.secrets API";
      serviceConfig = {
        Type = "dbus";
        ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
        BusName = "org.freedesktop.secrets";
      };
      aliases = [
        "dbus-org.freedesktop.secrets.service"
        "dbus-org.kde.kwalletd5.service"
      ];
    };
    services.dbus.packages = [
      (pkgs.writeTextFile {
        name = "org.freedesktop.secrets.kwallet.service";
        destination = "/share/dbus-1/services/org.freedesktop.secrets.service";
        text = ''
          [D-BUS Service]
          Name=org.freedesktop.secrets
          SystemdService=dbus-org.freedesktop.secrets.service
        '';
      })
    ];

    _custom.hm = {
      home.sessionVariables.SSH_ASKPASS_REQUIRE = "prefer";

      xdg.configFile."kwalletrc".source = ./dotfiles/kwalletrc;

      systemd.user.services.pam-kwallet-init = {
        Unit = {
          Description = "Kwallet";
          PartOf = [ "graphical-session-pre.target" ];
        };
        Service = {
          ExecStart =
            "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
          Restart = "on-abort";
        };
        Install.WantedBy = [ "graphical-session-pre.target" ];
      };
    };
  };
}
