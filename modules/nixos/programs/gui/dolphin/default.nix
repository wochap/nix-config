{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.dolphin;
in {
  options._custom.programs.dolphin.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
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
    ];
  };
}
