{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ kanshi ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "kanshi/config".text = ''
          profile docked {
            output "eDP-1" disable
            output "Goldstar Company Ltd LG ULTRAGEAR 112NTLEL9832" scale 1
          }

          profile undocked {
            output "eDP-1" scale 2
          }
        '';
      };
    };
  };
}
