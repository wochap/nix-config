{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.docker;
in {
  options._custom.docker = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose ];

    virtualisation.docker.enable = true;

    users.users.${userName}.extraGroups = [ "docker" ];
  };
}
