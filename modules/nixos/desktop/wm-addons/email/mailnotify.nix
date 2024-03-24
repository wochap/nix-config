{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in {
  config = lib.mkIf cfg.enable {
    _custom.hm.systemd.user.services.mailnotify = lib._custom.mkWaylandService {
      Unit = {
        Description = "mailnotify daemon";
        Documentation = "https://github.com/sumnerevans/mailnotify";
      };
      Service = {
        ExecStart = ''
          ${pkgs._custom.mailnotify}/bin/mailnotify \
            ${hmConfig.accounts.email.maildirBasePath} \
            ${pkgs.reversal-icon-theme}/share/icons/Reversal/apps/scalable/internet-mail.svg
        '';
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
