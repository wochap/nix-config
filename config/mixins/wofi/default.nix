{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [ wofi ];

      etc = {
        "scripts/wofi-clipboard.sh" = {
          source = ./scripts/wofi-clipboard.sh;
          mode = "0755";
        };
      };
    };
  };
}

