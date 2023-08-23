{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool
        filelight # view disk usage
        qbittorrent

        # APPS MEDIA (Comment on first install)
        libsForQt5.kdenlive
        localPkgs.stremio
        obs-studio # video capture
        # kdeApplications.kdenlive # video editor
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
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
