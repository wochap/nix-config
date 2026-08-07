{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.gnome-keyring;
in
{
  options._custom.security.gnome-keyring = {
    enable = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          libgnome-keyring
          libsecret # secret-tool
        ];

        programs.seahorse.enable = true;

        services.gnome.gnome-keyring.enable = true;

        # Disable gcr-ssh-agent since we use standard ssh-agent via pam_ssh
        services.gnome.gcr-ssh-agent.enable = false;

        xdg.portal.config = {
          common."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          Hyprland."org.freedesktop.impl.portal.Secret" = lib.mkIf config._custom.desktop.hyprland.enable [
            "gnome-keyring"
          ];
        };

        _custom.hm = {
          # disable kwallet
          xdg.configFile."kwalletrc".source = ./dotfiles/kwalletrc;

          systemd.user.services.gnome-keyring = {
            Unit = {
              Description = "GNOME Keyring";
              PartOf = [ "graphical-session-pre.target" ];
            };
            Service = {
              # Use wrapped gnome-keyring-daemon with cap_ipc_lock=ep
              ExecStart = lib.mkForce "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets";
              Restart = "on-abort";
            };
            Install.WantedBy = [ "graphical-session-pre.target" ];
          };
        };
      }

      (lib.mkIf cfg.enableLuksIntegration {
        security.pam.services = {
          login.enableGnomeKeyring = true;
          greetd.enableGnomeKeyring = config._custom.desktop.greetd.enable;
        };
        _custom.security.pam.enableLuksIntegration = true;
        _custom.desktop.greetd.enableLuksIntegration = config._custom.desktop.greetd.enable;
      })
    ]
  );
}
