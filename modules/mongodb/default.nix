{ config, pkgs, lib, ... }:

let cfg = config._custom.mongodb;
in {
  options._custom.mongodb = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mongodb-compass
      mongodb-tools
      robo3t
    ];

    services.mongodb = {
      enable = true;

      # custom mongodb versions took 18m to build
      package = pkgs.prevstable-mongodb.mongodb-4_2;

      # HACK: update the following values
      # if changing mongodb version gives errors
      pidFile = "/run/mongodb_nani4.pid";
      dbpath = "/var/db/mongodb_nani4";
    };
  };
}
