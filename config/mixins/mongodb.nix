{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      mongodb-compass
      mongodb-tools
      robo3t
    ];

    services.mongodb = {
      enable = true;
      # pkgs.mongodb-3_6 took 18m to build
      package = pkgs.mongodb-3_6;
      # enableAuth = true;
      # initialRootPassword = "root";
    };
  };
}
