# keycodes: https://gist.github.com/rickyzhang82/8581a762c9f9fc6ddb8390872552c250
{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.ydotool;
in {
  options._custom.desktop.ydotool = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ydotool ];

    _custom.hm = {
      systemd.user.services.ydotoold = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description = "Generic command-line automation tool (no X!)";
            Documentation = "https://github.com/ReimuNotMoe/ydotool";
          };
          Service = {
            ExecStart = "${pkgs.ydotool}/bin/ydotoold";
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Type = "simple";
            Restart = "always";
            KillMode = "process";
            TimeoutSec = 180;
          };
        });
    };
  };
}
