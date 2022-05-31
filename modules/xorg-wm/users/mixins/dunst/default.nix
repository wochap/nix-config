{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/xorg-wm/users/mixins/dunst";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ dunst libnotify gnome-icon-theme ];
      etc = {
        "assets/notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };

        "scripts/dunst-toggle-mode.sh" = {
          source = ./scripts/dunst-toggle-mode.sh;
          mode = "0755";
        };
        "scripts/dunst-start.sh" = {
          source = ./scripts/dunst-start.sh;
          mode = "0755";
        };
        "scripts/play_notification.sh" = {
          text = ''
            #! ${pkgs.bash}/bin/bash

            declare -i last_called=0
            declare -i throttle_by=1

            @debounce() {
              if [[ ! -f ./executing ]]
              then
                touch ./executing
                "$@"
                retVal=$?
                {
                  sleep $throttle_by
                  if [[ -f ./on-finish ]]
                  then
                    "$@"
                    rm -f ./on-finish
                  fi
                  rm -f ./executing
                } &
                return $retVal
              elif [[ ! -f ./on-finish ]]
              then
                touch ./on-finish
              fi
            }

            @debounce ${pkgs.pulseaudio}/bin/paplay /etc/assets/notification.flac

            wait $(jobs -p)
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
