{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../../../packages { pkgs = pkgs; };
in
{
  config = {
    environment.etc = {
      "notification.flac" = {
        source = ./assets/notification.flac;
        mode = "0755";
      };

      "play_notification.sh" = {
        text = ''
          #! ${pkgs.bash}/bin/bash
          ${pkgs.pulseaudio}/bin/paplay /etc/notification.flac
        '';
        mode = "0755";
      };
    };

    home-manager.users.gean = {
      services.dunst = {
        enable = true;
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
          # TODO: add missing icons to WhiteSur-dark
          # name = "WhiteSur-dark";
          # package = localPkgs.whitesur-dark-icons;
        };
        settings = (import ./dotfiles/dunstrc.nix);
      };
    };
  };
}
