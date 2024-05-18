{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.qt;
in {
  options._custom.programs.qt.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        anki # mnemonic tool
        filelight # view disk usage
        qbittorrent

        libsForQt5.ark # archive manager

        # kcmshell5 to change kde settings on wm
        # e.g. default terminal on dolphin
        libsForQt5.kde-cli-tools

        # dolplhin
        libsForQt5.dolphin
        libsForQt5.dolphin-plugins
        libsForQt5.kio-extras # thumbnails
        libsForQt5.kdegraphics-thumbnailers # thumbnails
        libsForQt5.qt5.qtimageformats # thumbnails
        libsForQt5.ffmpegthumbs # thumbnails

        # kdenlive
        libsForQt5.kdenlive
        # glaxnimate

        # APPS MEDIA (Comment on first install)
        stremio
        # nomacs # image viewer/editor
        # olive-editor # video editor
        # openshot-qt # video editor
      ];
    };

    _custom.hm = {
      xdg.configFile."obs-studio/themes".source =
        "${inputs.catppuccin-obs}/themes";

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs; [
          obs-studio-plugins.wlrobs

          obs-studio-plugins.obs-vkcapture
          obs-studio-plugins.obs-gstreamer
          obs-studio-plugins.obs-vaapi

          obs-studio-plugins.obs-source-record
          obs-studio-plugins.obs-shaderfilter
          obs-studio-plugins.obs-gradient-source
          obs-studio-plugins.obs-rgb-levels-filter
          # obs-studio-plugins.obs-backgroundremoval # takes too long to build
        ];
      };
    };
  };
}

