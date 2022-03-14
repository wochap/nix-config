{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [ docker-compose ];

    virtualisation.docker.enable = true;

    users.users.${userName}.extraGroups = [ "docker" ];
  };
}
