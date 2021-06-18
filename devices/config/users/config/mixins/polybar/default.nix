{ config, pkgs, lib,  ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    environment = {
      sessionVariables = {
        POLYBAR_HEIGHT = "48";
      };
      etc = {
        "scripts/polybar-show.sh" = {
          text = ''
            #!/usr/bin/env bash

            polybar-msg cmd show
            bspc config -m focused top_padding $(($POLYBAR_HEIGHT + $BSPWM_WINDOW_GAP))
          '';
          mode = "0755";
        };
        "scripts/polybar-hide.sh" = {
          text = ''
            #!/usr/bin/env bash

            polybar-msg cmd hide
            bspc config -m focused top_padding 0
          '';
          mode = "0755";
        };
      };
    };
    home-manager.users.gean = lib.mkIf isXorg {
      home.file = {
        ".config/polybar/main.ini".source = ./dotfiles/main.ini;
        ".config/polybar/scripts/docker_info.sh".source = ./dotfiles/scripts/docker_info.sh;
        ".config/polybar/scripts/get_gpu_status.sh".source = ./dotfiles/scripts/get_gpu_status.sh;
        ".config/polybar/scripts/get_spotify_status.sh".source = ./dotfiles/scripts/get_spotify_status.sh;
        ".config/polybar/scripts/get_vram_status.sh".source = ./dotfiles/scripts/get_vram_status.sh;
        ".config/polybar/scripts/scroll_spotify_status.sh".source = ./dotfiles/scripts/scroll_spotify_status.sh;
        ".config/polybar/scripts/bspwm_monocle_windows.sh" = {
          source = ./dotfiles/scripts/bspwm_monocle_windows.sh;
          executable = true;
        };
      };
      services.polybar = {
        enable = true;
        config = ./dotfiles/config.ini;
        # Fixes: https://github.com/nix-community/home-manager/issues/1616
        script = "";
        package = pkgs.polybar.override {
          alsaSupport = true;
          mpdSupport = true;
          pulseSupport = true;
        };
      };
    };
  };
}
