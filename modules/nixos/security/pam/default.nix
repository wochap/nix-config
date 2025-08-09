{ config, pkgs, lib, ... }:

let cfg = config._custom.security.pam;
in {
  options._custom.security.pam = {
    enable = lib.mkEnableOption { };
    enablePamSystemdLoadkey = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # unlock keyring using luks passphrase
    security.pam.services.login.rules.auth.systemd_loadkey = {
      enable = cfg.enablePamSystemdLoadkey;
      order = config.security.pam.services.login.rules.auth.gnome_keyring.order
        - 1;
      control = "optional";
      modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
    };
  };
}
