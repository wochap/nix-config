{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool

        # APPS MEDIA (Comment on first install)
        inkscape # photo editor cli/gui
        obs-studio # video capture
        # kdeApplications.kdenlive # video editor
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
        stremio
      ];
    };
  };
}