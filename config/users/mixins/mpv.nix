{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.sessionVariables = { VIDEO = "mpv"; };

      xdg.configFile = {
        "mpv/scripts/mordenx.lua".source =
          "${inputs.mpv-osc-morden-x}/mordenx.lua";
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
