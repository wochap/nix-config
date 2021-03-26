{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    virtualisation.docker.enable = true;
  };
}
