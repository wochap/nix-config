{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.mouseless;

  woints = inputs.woints.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options._custom.desktop.mouseless.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ woints ];

    _custom.desktop.a11y.enable = lib.mkDefault true;

    _custom.hm = {
      systemd.user.services.wointsd = lib._custom.mkWaylandService {
        Unit = {
          Description = "woints hint daemon";
          After = [
            "graphical-session.target"
            "a11y-enable.service"
          ];
          Wants = [ "a11y-enable.service" ];
        };
        Service = {
          ExecStart = "${woints}/bin/wointsd";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
  };
}
