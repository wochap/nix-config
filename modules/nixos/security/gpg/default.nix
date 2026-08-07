{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.gpg;
in
{
  options._custom.security.gpg = {
    enable = lib.mkEnableOption { };
    enableGpgAgent = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        _custom.hm = {
          programs.gpg.enable = true;

          services.gpg-agent = lib.mkIf cfg.enableGpgAgent {
            enable = true;
            enableSshSupport = false; # ssh-agent is handled by gcr-ssh-agent
            pinentryPackage = pkgs.pinentry-gnome3;
          };
        };
      }

      (lib.mkIf cfg.enableLuksIntegration {
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
    ]
  );
}
