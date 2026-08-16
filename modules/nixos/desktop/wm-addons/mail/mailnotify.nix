{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm.systemd.user.services.mailnotify = lib._custom.mkWaylandService {
      Unit = {
        Description = "mailnotify daemon";
        Documentation = "https://github.com/wochap/mailnotify";
      };
      Service = {
        ExecStart = ''
          ${pkgs._custom.mailnotify}/bin/mailnotify \
            --app-name=mailnotify \
            --app-icon=internet-mail \
            --icon=internet-mail \
            --hint=string:custom-sound:message \
            ${hmConfig.accounts.email.maildirBasePath}
        '';
        Restart = "always";
        RestartSec = 5;
      }
      // lib._custom.userServiceHardening
      // {
        ProtectHome = "tmpfs";
        BindReadOnlyPaths = [ hmConfig.accounts.email.maildirBasePath ];
        RestrictAddressFamilies = [ "AF_UNIX" ];
      };
    };
  };
}
