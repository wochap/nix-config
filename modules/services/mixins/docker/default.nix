{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.services.docker;
in {
  options._custom.services.docker = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose lazydocker ];

    virtualisation.docker.enable = true;

    users.users.${userName}.extraGroups = [ "docker" ];
  };
}
