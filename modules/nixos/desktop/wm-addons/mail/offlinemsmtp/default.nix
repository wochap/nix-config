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
  offlinemsmtp-toggle-mode = pkgs.writeScriptBin "offlinemsmtp-toggle-mode" (
    builtins.readFile ./offlinemsmtp-toggle-mode.sh
  );
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [
        offlinemsmtp-toggle-mode
        pkgs._custom.offlinemsmtp
      ];

      systemd.user.services.offlinemsmtp = lib._custom.mkWaylandService {
        Unit = {
          Description = "offlinemsmtp daemon";
          Documentation = "https://github.com/sumnerevans/offlinemsmtp";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 3;
        };
        Service = {
          ExecStart = ''
            ${pkgs._custom.offlinemsmtp}/bin/offlinemsmtp \
              --daemon \
              --loglevel DEBUG \
              --file ${hmConfig.xdg.configHome}/msmtp/config \
              --send-mail-file ${hmConfig.home.homeDirectory}/tmp/offlinemsmtp-sendmail
          '';
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  };
}
