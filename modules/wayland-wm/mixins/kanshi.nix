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
            output "Apple Computer Inc Color LCD Unknown" disable
            output "Goldstar Company Ltd LG ULTRAGEAR 112NTLEL9832" mode 3440x1440@99.990Hz scale 1
          }

          profile undocked {
            output "Apple Computer Inc Color LCD Unknown" scale 2
          }
        '';
      };
    };
  };
}
