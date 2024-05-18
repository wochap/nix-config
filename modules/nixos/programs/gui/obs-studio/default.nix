{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.obs-studio;
in {
  options._custom.programs.obs-studio.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
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
