{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.mpv;
  isWayland = config._custom.globals.displayServer == "wayland";
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
        "mpv/scripts/mordenx.lua".source = ./dotfiles/mordenx.lua;
        "mpv/fonts/Material-Design-Iconic-Font.ttf".source =
          "${inputs.mpv-osc-morden-x}/Material-Design-Iconic-Font.ttf";
      };

      programs.mpv = {
        enable = true;
        config = {
          osc = false;
          border = false;

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
          # pkgs.mpvScripts.sponsorblock
          # pkgs.mpvScripts.youtube-quality
          # pkgs.mpvScripts.thumbnail
        ];
      };
    };
  };
}
