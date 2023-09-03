{ config, pkgs, lib, ... }:

with pkgs;
let
  cfg = config._custom.wm.email;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) offlinemsmtp;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
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
