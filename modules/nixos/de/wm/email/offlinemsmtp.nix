{ config, pkgs, lib, ... }:

with pkgs;
let
  cfg = config._custom.wm.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) offlinemsmtp;
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      systemd.user.services.offlinemsmtp = {
        Unit = {
          Description = "offlinemsmtp daemon";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = ''
            ${offlinemsmtp}/bin/offlinemsmtp \
              --daemon \
              --loglevel DEBUG \
              --file ${hmConfig.xdg.configHome}/msmtp/config \
              --send-mail-file ${hmConfig.home.homeDirectory}/tmp/offlinemsmtp-sendmail
          '';
          Restart = "always";
          RestartSec = 5;
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
