{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.wm.dbus;
in {
  options._custom.wm.dbus = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        # For a polkit authentication agent
        polkit_gnome
      ];

    security.polkit.enable = true;
    services.dbus.enable = true;
    services.gnome.glib-networking.enable = true;
    services.udisks2.enable = true;
    services.hardware.bolt.enable = true; # Thunderbolt
    services.xserver.updateDbusEnvironment = true;
    services.logind.lidSwitch = "ignore";

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

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
