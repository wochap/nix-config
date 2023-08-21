{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool

        # APPS MEDIA (Comment on first install)
        obs-studio # video capture
        # kdeApplications.kdenlive # video editor
        libsForQt5.kdenlive
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
        localPkgs.stremio
      ];
    };

    home-manager.users.${userName} = {
      services.kdeconnect = {
        enable = true;
        indicator = false;
      };
    };
  };
}
