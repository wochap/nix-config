{ config, pkgs, lib, ... }:

let cfg = config._custom.security.polkit;
in {
  options._custom.security.polkit.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        # polkit authentication agent
        polkit_gnome
      ];

    services.dbus.enable = lib.mkDefault true;
    security.polkit.enable = true;

    _custom.hm.systemd.user.services.polkit-gnome-authentication-agent-1 =
      lib._custom.mkWaylandService {
        Unit = {
          Description = "polkit-gnome-authentication-agent-1";
          Documentation = "https://gitlab.gnome.org/Archive/policykit-gnome";
        };
        Service = {
          Type = "simple";
          ExecStart =
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
  };
}

