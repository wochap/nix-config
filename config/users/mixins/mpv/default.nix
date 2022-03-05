{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
  theme = config._theme;
in {
  config = {
    home-manager.users.${userName} = {
      home.sessionVariables = { VIDEO = "mpv"; };

      home.packages = with pkgs;
        [
          subdl # cli to download subtitles
          # python39Packages.subdownloader
        ];

      xdg.configFile = {
        "mpv/scripts/mordenx.lua".source = ./dotfiles/mordenx.lua;
        "mpv/fonts/Material-Design-Iconic-Font.ttf".source =
          "${inputs.mpv-osc-morden-x}/Material-Design-Iconic-Font.ttf";
        "mpv/script-opts/osc.conf".text = ''
          windowcontrols=no
        '';
      };

      programs.mpv = {
        enable = true;
        config = {
          osc = false;
          border = false;
          background = theme.background;

          autofit-larger = "75%x75%";
          gpu-context = lib.mkIf (isWayland) "wayland";
          hwdec = "vaapi";
          hwdec-codecs = "all";
          keep-open = true;
          osd-font = "JetBrainsMono";
          pause = true;
          video-sync = "display-resample";
          vo = "gpu";
        };
        scripts = [
          pkgs.mpvScripts.mpris
          # pkgs.mpvScripts.sponsorblock
          # pkgs.mpvScripts.youtube-quality
          # pkgs.mpvScripts.thumbnail
        ];
      };
    };
  };
}
