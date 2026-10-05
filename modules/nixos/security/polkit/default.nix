{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.polkit;
  hyprpolkitagent-final = pkgs.hyprpolkitagent;
  # quickshell registers its own agent (SAuth.qml), only one agent per session
  useShellAgent = config._custom.desktop.quickshell.authDialogs.active.polkit;
in
{
  options._custom.security.polkit.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.optionals (!useShellAgent) [
      # polkit authentication agent
      hyprpolkitagent-final
    ];

    services.dbus.enable = lib.mkDefault true;
    security.polkit.enable = true;

    # NOTE: doesn't work as expected if you have more than 1 TTY active
    _custom.hm.systemd.user.services.hyprpolkitagent = lib.mkIf (!useShellAgent) (
      lib._custom.mkWaylandService {
        Unit.Description = "Hyprland PolicyKit Agent";
        Service = {
          Type = "simple";
          ExecStart = "${hyprpolkitagent-final}/libexec/hyprpolkitagent";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      }
    );
  };
}
