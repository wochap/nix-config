{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool
        filelight # view disk usage
        qbittorrent

        # APPS MEDIA (Comment on first install)
        libsForQt5.kdenlive
        stremio
        obs-studio # video capture
        # kdeApplications.kdenlive # video editor
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
      ];
    };

    programs.kdeconnect.enable = true;

    home-manager.users.${userName} = {
      services.kdeconnect = {
        enable = true;
        indicator = false;
      };
    };
  };
}
