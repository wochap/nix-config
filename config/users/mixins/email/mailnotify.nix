{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  localPkgs = import ../../../packages { inherit pkgs lib; };
  inherit (localPkgs) mailnotify;
in {
  config = {
    home-manager.users.${userName} = {
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
