{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/dunst";
in {
  config = {
    environment = {
      systemPackages = with pkgs; [ dunst libnotify ];
      etc = {
        "assets/notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };

        "scripts/play_notification.sh" = {
          text = ''
            #! ${pkgs.bash}/bin/bash

            ${pkgs.pulseaudio}/bin/paplay /etc/assets/notification.flac
          '';
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "dunst/dunstrc".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/dunstrc";
      };
    };
  };
}
