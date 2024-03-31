{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.mpv;
  isWayland = config._custom.globals.displayServer == "wayland";
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.mpv.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.sessionVariables.VIDEO = "mpv";

      home.packages = with pkgs;
        [
          subdl # cli to download subtitles
          # python39Packages.subdownloader
        ];

      xdg.configFile = {
        "mpv/script-opts/osc.conf".text = ''
          windowcontrols=no
        '';
        "mpv/scripts-opts/stats.conf".source =
          "${inputs.catppuccin-mpv}/themes/mocha/scripts-opts/stats.conf";
      };

      programs.mpv = {
        enable = true;
        config = {
          # uosc script recommended config
          osc = false;
          border = false;

          # catppuccin mpv theme
          background = themeColors.base;
          osd-back-color = themeColors.overlay0;
          osd-border-color = themeColors.crust;
          osd-color = themeColors.text;
          osd-shadow-color = themeColors.base;

          autofit-larger = "75%x75%";
          gpu-context = lib.mkIf isWayland "wayland";
          hwdec-codecs = "all";
          keep-open = true;
          osd-font = "Iosevka NF";
          pause = true;
          video-sync = "display-resample";

          # enable hardware acceleration
          hwdec = "auto-safe";
          vo = "gpu";
        };
        profiles = {
          igpu-amd = {
            hwdec = "auto-safe";
            vo = "gpu";
          };
          dgpu-nvidia = {
            hwdec = "nvdec-copy";
            vo = "gpu-next";
          };
        };
        scripts = with pkgs; [
          mpvScripts.mpris
          mpvScripts.thumbfast
          mpvScripts.uosc
          mpvScripts.cutter
          mpvScripts.quality-menu
          mpvScripts.mpv-cheatsheet
          # pkgs.mpvScripts.sponsorblock
        ];
      };
    };
  };
}
