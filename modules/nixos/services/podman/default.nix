{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.podman;
in
{
  options._custom.services.podman = {
    enable = lib.mkEnableOption "Podman";
    dockerCompat = lib.mkEnableOption { };
    rootless = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      podman-compose
    ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = cfg.dockerCompat;
      dockerSocket.enable = cfg.dockerCompat && !cfg.rootless;

      defaultNetwork.settings.dns_enabled = true;
    };

    # The upstream module enables both sockets. Only activate the socket for
    # the selected mode so a rootless setup does not also expose rootful Podman.
    systemd.sockets.podman.wantedBy = lib.mkIf cfg.rootless (lib.mkForce [ ]);
    systemd.user.sockets.podman.wantedBy = lib.mkIf (!cfg.rootless) (lib.mkForce [ ]);

    # Docker-compatible clients (including lazydocker and compose) need the
    # per-user socket path. Podman itself discovers rootless storage normally.
    environment.extraInit = lib.mkIf (cfg.dockerCompat && cfg.rootless) ''
      if [ -z "''${DOCKER_HOST-}" ] && [ -n "''${XDG_RUNTIME_DIR-}" ]; then
        export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
      fi
    '';
  };
}
