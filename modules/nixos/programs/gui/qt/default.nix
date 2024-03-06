{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.qt;
in {
  options._custom.programs.qt.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
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

    programs.kdeconnect = {
      enable = true;
      package =
        lib.mkIf config._custom.de.gnome.enable pkgs.gnomeExtensions.gsconnect;
    };

    _custom.hm = {
      services.kdeconnect = {
        enable = true;
        indicator = false;
      };
    };
  };
}

