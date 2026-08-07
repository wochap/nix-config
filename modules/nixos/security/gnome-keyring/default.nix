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
    enableSshAgent = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            libgnome-keyring
            libsecret # secret-tool
          ];

          variables.SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
        };

        programs.seahorse.enable = true;

        services.gnome.gnome-keyring.enable = true;

        # enable gcr-ssh-agent to automatically manage SSH keys via GNOME Keyring
        services.gnome.gcr-ssh-agent.enable = cfg.enableSshAgent;

        xdg.portal.config = {
          common."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          Hyprland."org.freedesktop.impl.portal.Secret" = lib.mkIf config._custom.desktop.hyprland.enable [
            "gnome-keyring"
          ];
        };

        _custom.hm = {
          # disable kwallet
          xdg.configFile."kwalletrc".source = ./dotfiles/kwalletrc;
        };
      }

      (lib.mkIf cfg.enableLuksIntegration {
        security.pam.services = {
          login = {
            enableGnomeKeyring = true;
            rules.auth.gnome_keyring.order = 98;
          };
          greetd = lib.mkIf config._custom.desktop.greetd.enable {
            enableGnomeKeyring = true;
            rules.auth.gnome_keyring.order = 98;
          };
        };
        _custom.security.pam.enableLuksIntegration = true;
        _custom.desktop.greetd.enableLuksIntegration = config._custom.desktop.greetd.enable;
      })
    ]
  );
}
