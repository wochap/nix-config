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
      rootless = {
        enable = true;
        setSocketVariable = true;
        # TODO: rootless docker can't use nvidia gpu
        # more info: https://github.com/NixOS/nixpkgs/issues/339999
        # daemon.settings.features.cdi = true;
      };
      extraOptions = lib.mkIf cfg.enableNvidia
        "--add-runtime nvidia=/run/current-system/sw/bin/nvidia-container-runtime";
    };

    hardware.nvidia-container-toolkit.enable = lib.mkIf cfg.enableNvidia true;
    # hardware.nvidia.nvidiaPersistenced = true;
  };
}
