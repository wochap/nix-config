{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in {
  config = lib.mkIf cfg.enable {
    _custom.hm.systemd.user.services.mailnotify = {
      Unit = {
        Description = "mailnotify daemon";
        PartOf = [ "wayland-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${pkgs._custom.mailnotify}/bin/mailnotify \
            ${hmConfig.accounts.email.maildirBasePath} \
            ${pkgs.numix-icon-theme-circle}/share/icons/Numix-Circle/48@2x/apps/mail-generic.svg
        '';
        Restart = "always";
        RestartSec = 5;
      };

      Install.WantedBy = [ "wayland-session.target" ];
    };
  };
}
