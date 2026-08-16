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
        }
        // lib._custom.userServiceHardening
        // {
          ProtectHome = "tmpfs";
          BindReadOnlyPaths = lib.unique (
            [ "${hmConfig.xdg.configHome}/msmtp/config" ]
            ++ lib.mapAttrsToList (_: acc: acc.passwordSecret.path) cfg.accounts
          );
          # The daemon creates this IPC endpoint and mail clients open it
          # later, so its containing queue directory must be shared.
          BindPaths = [ "${hmConfig.home.homeDirectory}/tmp" ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    };
  };
}
