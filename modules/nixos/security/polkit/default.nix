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

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "wayland-session.target" ];
      wants = [ "wayland-session.target" ];
      after = [ "wayland-session.target" ];

      serviceConfig = {
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

