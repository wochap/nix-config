{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.kwallet;
in
{
  options._custom.security.kwallet = {
    enable = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          kdePackages.kwallet # provides helper service
          kdePackages.kwalletmanager # A GUI to manage your KWallet
          kdePackages.kwallet-pam # provides helper service
        ];

        xdg.portal.extraPortals = with pkgs; [ kdePackages.kwallet ];

        xdg.portal.config = {
          common."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
          Hyprland."org.freedesktop.impl.portal.Secret" = lib.mkIf config._custom.desktop.hyprland.enable [
            "kwallet"
          ];
        };

        systemd.user.services."dbus-org.freedesktop.secrets.kwallet" = {
          description = "Allow KWallet to be D-Bus activated for the generic org.freedesktop.secrets API";
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
          xdg.configFile."kwalletrc".source = ./dotfiles/kwalletrc;

          systemd.user.services.pam-kwallet-init = {
            Unit = {
              Description = "Kwallet";
              PartOf = [ "graphical-session-pre.target" ];
            };
            Service = {
              ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
              Restart = "on-abort";
            };
            Install.WantedBy = [ "graphical-session-pre.target" ];
          };
        };
      }

      (lib.mkIf cfg.enableLuksIntegration {
        security.pam.services = {
          login = {
            kwallet = {
              enable = true;
              package = pkgs.kdePackages.kwallet-pam;
              forceRun = true;
            };
            rules.session.kwallet.settings.auto_start = true;
          };

          greetd = lib.mkIf config._custom.desktop.greetd.enable {
            kwallet = {
              enable = true;
              package = pkgs.kdePackages.kwallet-pam;
              forceRun = true;
            };
            rules.session.kwallet.settings.auto_start = true;
          };
        };

        _custom.security.pam.enableLuksIntegration = true;
        _custom.desktop.greetd.enableLuksIntegration = config._custom.desktop.greetd.enable;
      })
    ]
  );
}
