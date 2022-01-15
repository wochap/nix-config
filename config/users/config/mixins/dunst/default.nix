{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../../../packages { pkgs = pkgs; lib = lib; };
  userName = config._userName;
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        dunst
      ];
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
      services.dunst = {
        enable = true;
        # TODO: add WAYLAND_DISPLAY
        # waylandDisplay = "";
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
        settings = (import ./dotfiles/dunstrc.nix { pkgs = pkgs; lib = lib; });
      };
    };
  };
}
