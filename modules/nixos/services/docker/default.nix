{ config, pkgs, lib, ... }:

let cfg = config._custom.services.docker;
in {
  options._custom.services.docker = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose lazydocker ];

    virtualisation.docker = {
      enable = true;
      enableNvidia = lib.mkIf cfg.enableNvidia true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      extraOptions = lib.mkIf cfg.enableNvidia
        "--add-runtime nvidia=/run/current-system/sw/bin/nvidia-container-runtime";
    };
  };
}
