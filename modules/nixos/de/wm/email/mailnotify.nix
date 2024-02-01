{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) mailnotify;
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      systemd.user.services.mailnotify = {
        Unit = {
          Description = "mailnotify daemon";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = ''
            ${mailnotify}/bin/mailnotify \
              ${hmConfig.accounts.email.maildirBasePath} \
              ${pkgs.numix-icon-theme-circle}/share/icons/Numix-Circle/48@2x/apps/mail-generic.svg
          '';
          Restart = "always";
          RestartSec = 5;
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}