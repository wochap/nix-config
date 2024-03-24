{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  offlinemsmtp-toggle-mode = pkgs.writeScriptBin "offlinemsmtp-toggle-mode"
    (builtins.readFile ./scripts/offlinemsmtp-toggle-mode.sh);
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [ offlinemsmtp-toggle-mode ];

      systemd.user.services.offlinemsmtp = lib._custom.mkWaylandService {
        Unit = {
          Description = "offlinemsmtp daemon";
          Documentation = "https://github.com/sumnerevans/offlinemsmtp";
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
