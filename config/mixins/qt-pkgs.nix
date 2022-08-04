{ config, pkgs, lib, ... }:

let localPkgs = import ../packages { inherit pkgs lib; };
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
  };
}
