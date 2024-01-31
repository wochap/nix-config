{ config, pkgs, lib, ... }:

let
  inherit (config._custom.globals) userName;
  cfg = config._custom.services.docker;
in {
  options._custom.services.docker = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose lazydocker ];

    virtualisation.docker.enable = true;
    virtualisation.docker.enableNvidia = lib.mkIf cfg.enableNvidia true;
    virtualisation.docker.extraOptions = lib.mkIf cfg.enableNvidia
      "--add-runtime nvidia=/run/current-system/sw/bin/nvidia-container-runtime";

    users.users.${userName}.extraGroups = [ "docker" ];
  };
}
