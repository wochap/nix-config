{ config, pkgs, lib, ... }:

with pkgs;
let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  localPkgs = import ../../../packages {
    pkgs = pkgs;
    lib = lib;
  };

  offlinemsmtp = localPkgs.offlinemsmtp;
in {
  config = {
    home-manager.users.${userName} = {

      systemd.user.services.offlinemsmtp = {
        Unit = {
          Description = "offlinemsmtp daemon";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = ''
            ${offlinemsmtp}/bin/offlinemsmtp --daemon \
              --loglevel DEBUG \
              --send-mail-file ${hmConfig.home.homeDirectory}/tmp/offlinemsmtp-sendmail \
              --file ${hmConfig.xdg.configHome}/msmtp/config
          '';
          Restart = "always";
          RestartSec = 5;
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
