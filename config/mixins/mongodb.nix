{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      unstable.mongodb-compass
      mongodb-tools
      robo3t
    ];

    services.mongodb = {
      enable = true;

      # custom mongodb versions took 18m to build
      package = pkgs.prevstable.mongodb-4_2;

      # HACK: update the following values
      # if changing mongodb version gives errors
      pidFile = "/run/mongodb_nani.pid";
      dbpath = "/var/db/mongodb_nani";
    };
  };
}
