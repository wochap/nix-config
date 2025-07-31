{ config, pkgs, lib, ... }:

let cfg = config._custom.services.docker;
in {
  options._custom.services.docker = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.shellAliases.lD = ''run-without-kpadding lazydocker "$@"'';

    environment.systemPackages = with pkgs;
      [ docker-compose lazydocker ]
      ++ lib.optionals cfg.enableNvidia [ nvidia-docker ];

    virtualisation.docker = {
      enable = true;
      # enable storage driver containerd
      daemon.settings.features.containerd-snapshotter = true;
      rootless = {
        enable = true;
        # sets DOCKER_HOST env var
        setSocketVariable = true;
        # enable storage driver containerd
        daemon.settings.features.containerd-snapshotter = true;
      };
      extraOptions = lib.mkIf cfg.enableNvidia
        "--add-runtime nvidia=/run/current-system/sw/bin/nvidia-container-runtime";
    };

    hardware.nvidia-container-toolkit.enable = lib.mkIf cfg.enableNvidia true;
    # reduce gpu startup latency
    # prevents gpu to enter in low-power state
    # hardware.nvidia.nvidiaPersistenced = true;
  };
}
