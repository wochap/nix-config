{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.tt;
  inherit (config._custom.globals) userName;
in
{
  options._custom.services.tt.daemon.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Run `tt daemon` as a user service. It owns $XDG_DATA_HOME/tt and the
      socket $XDG_RUNTIME_DIR/tt.sock; without it the CLI spawns one on demand.
    '';
  };

  config = lib.mkIf (cfg.enable && cfg.daemon.enable) {
    _custom.hm.systemd.user.services.tt = {
      Unit = {
        Description = "tt task and time tracker daemon";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} daemon";
        Restart = "on-failure";
        RestartSec = 2;
        # hooks run with the daemon's environment
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${userName}/bin"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
