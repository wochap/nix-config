{ config, pkgs, lib, ... }:

let
  cfg = config._custom.security.polkit;
  hyprpolkitagent-final = pkgs.hyprpolkitagent;
in {
  options._custom.security.polkit.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        # polkit authentication agent
        hyprpolkitagent-final
      ];

    services.dbus.enable = lib.mkDefault true;
    security.polkit.enable = true;

    # NOTE: doesn't work as expected if you have more than 1 TTY active
    _custom.hm.systemd.user.services.hyprpolkitagent =
      lib._custom.mkWaylandService {
        Unit.Description = "Hyprland PolicyKit Agent";
        Service = {
          Type = "simple";
          ExecStart = "${hyprpolkitagent-final}/libexec/hyprpolkitagent";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
  };
}

