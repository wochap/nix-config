{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.gpg;
  # quickshell auth dialog, falls back to pinentry-gnome3 when the shell is down
  useShellPinentry = config._custom.desktop.quickshell.authDialogs.active.pinentry;
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
            pinentry =
              if useShellPinentry then
                {
                  package = pkgs._custom.shell-auth;
                  program = "pinentry-shell";
                }
              else
                { package = pkgs.pinentry-gnome3; };
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
