{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.qt;
in {
  options._custom.programs.qt.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool
        kdePackages.filelight # view disk usage
        qbittorrent

        kdePackages.kalgebra
        kdePackages.kdenlive
        # glaxnimate

        # APPS MEDIA (Comment on first install)
        stremio
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
      ];
    };
  };
}

