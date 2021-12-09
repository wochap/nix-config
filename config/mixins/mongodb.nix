{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      mongodb-tools
    ];

    services.mongodb = {
      enable = true;
      # enableAuth = true;
      # initialRootPassword = "root";
    };
  };
}
