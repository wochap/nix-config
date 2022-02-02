{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment = { systemPackages = with pkgs; [ kanshi ]; };

    home-manager.users.${userName} = {
      # TODO: change to way-displays
      xdg.configFile = {
        "kanshi/config".text = ''
          profile docked {
            output "eDP-1" disable
            output "Goldstar Company Ltd LG HDR 4K 0x0000BF0C" scale 1.5
          }

          profile undocked {
            output "eDP-1" scale 2.0
          }
        '';
      };

      # services.kanshi = {
      #   enable = true;
      #
      #   profiles = {
      #     undocked = {
      #       outputs = [{
      #         criteria = "eDP-1";
      #         scale = 2.0;
      #       }];
      #     };
      #     docked = {
      #       outputs = [
      #         {
      #           criteria = "eDP-1";
      #           status = "disable";
      #         }
      #         {
      #           scale = 1.5;
      #           criteria = "Goldstar Company Ltd LG HDR 4K 0x0000BF0C";
      #         }
      #       ];
      #     };
      #   };
      # };
    };
  };
}

