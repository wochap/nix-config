{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gui.mpv;
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in {
  options._custom.gui.mpv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.sessionVariables = { VIDEO = "mpv"; };

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
          hwdec = "vaapi";
          hwdec-codecs = "all";
          keep-open = true;
          osd-font = "Iosevka Nerd Font";
          pause = true;
          video-sync = "display-resample";
          vo = "gpu";
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
