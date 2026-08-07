{ config, pkgs, lib, ... }:

let
  cfg = config._custom.security.gpg;
in
{
  options._custom.security.gpg = {
    enable = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      _custom.hm = {
        programs.gpg.enable = true;
      };
    }

    (lib.mkIf cfg.enableLuksIntegration {
      _custom.hm = {
        services.gpg-agent = {
          enable = true;
          enableSshSupport = false; # ssh-agent is handled separately by pam_ssh
          pinentryPackage = pkgs.pinentry-gnome3;
        };
      };

      security.pam.services = {
        login.rules.auth.gnupg = {
          order = 20;
          control = "optional";
          modulePath = "${pkgs.pam_gnupg}/lib/security/pam_gnupg.so";
        };
        login.rules.session.gnupg = {
          order = 20;
          control = "optional";
          modulePath = "${pkgs.pam_gnupg}/lib/security/pam_gnupg.so";
        };
        greetd.rules.auth.gnupg = {
          order = 20;
          control = "optional";
          modulePath = "${pkgs.pam_gnupg}/lib/security/pam_gnupg.so";
        };
        greetd.rules.session.gnupg = {
          order = 20;
          control = "optional";
          modulePath = "${pkgs.pam_gnupg}/lib/security/pam_gnupg.so";
        };
      };
    })
  ]);
}
