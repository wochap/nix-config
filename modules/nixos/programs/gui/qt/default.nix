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
        libsForQt5.dolphin

        # APPS MEDIA (Comment on first install)
        libsForQt5.kdenlive
        stremio
        # kdeApplications.kdenlive # video editor
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
      ];
    };

    programs.kdeconnect = {
      enable = true;
      package = lib.mkIf config._custom.desktop.gnome.enable
        pkgs.gnomeExtensions.gsconnect;
    };

    _custom.hm = {
      programs.obs-studio = {
        enable = true;
        plugins = with pkgs; [
          obs-studio-plugins.obs-vkcapture
          obs-studio-plugins.obs-gstreamer
          obs-studio-plugins.obs-vaapi

          obs-studio-plugins.obs-source-record
          obs-studio-plugins.obs-backgroundremoval
        ];
      };

      services.kdeconnect = {
        enable = true;
        indicator = false;
      };
    };
  };
}

