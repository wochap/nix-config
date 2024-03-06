{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  offlinemsmtp-toggle-mode = pkgs.writeScriptBin "offlinemsmtp-toggle-mode"
    (builtins.readFile ./scripts/offlinemsmtp-toggle-mode.sh);
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = [ offlinemsmtp-toggle-mode ];

      systemd.user.services.offlinemsmtp = {
        Unit = {
          Description = "offlinemsmtp daemon";
          PartOf = [ "wayland-session.target" ];
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

        Install.WantedBy = [ "wayland-session.target" ];
      };
    };
  };
}
