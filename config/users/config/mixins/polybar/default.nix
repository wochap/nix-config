{ config, pkgs, lib,  ... }:

let
  userName = config._userName;
  isXorg = config._displayServer == "xorg";
  localPkgs = import ../../../../packages { pkgs = pkgs; lib = lib; };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        localPkgs.zscroll # scroll text in shells
      ];
      sessionVariables = {
        # POLYBAR_HEIGHT = 48 + 3 * 2
        POLYBAR_HEIGHT = "54";
        POLYBAR_MARGIN = "25";
      };
      etc = {
        "scripts/polybar-start.sh" = {
          source = ./dotfiles/scripts/polybar-start.sh;
          mode = "0755";
        };
        "scripts/polybar-show.sh" = {
          text = ''
            #!/usr/bin/env bash

            bspc config top_padding $(($POLYBAR_HEIGHT + $POLYBAR_MARGIN))
            polybar-msg cmd show
          '';
          mode = "0755";
        };
        "scripts/polybar-hide.sh" = {
          text = ''
            #!/usr/bin/env bash

            bspc config top_padding 0
            polybar-msg cmd hide
          '';
          mode = "0755";
        };
      };
    };
    home-manager.users.${userName} = lib.mkIf isXorg {
      xdg.configFile = {
        "polybar/main.ini".source = ./dotfiles/main.ini;
        "polybar/scripts/docker_info.sh".source = ./dotfiles/scripts/docker_info.sh;
        "polybar/scripts/get_gpu_status.sh".source = ./dotfiles/scripts/get_gpu_status.sh;
        "polybar/scripts/get_spotify_status.sh".source = ./dotfiles/scripts/get_spotify_status.sh;
        "polybar/scripts/get_vram_status.sh".source = ./dotfiles/scripts/get_vram_status.sh;
        "polybar/scripts/scroll_spotify_status.sh".source = ./dotfiles/scripts/scroll_spotify_status.sh;
        "polybar/scripts/bspwm_monocle_windows.sh" = {
          source = ./dotfiles/scripts/bspwm_monocle_windows.sh;
          executable = true;
        };
        "polybar/scripts/bspwm_hidden_windows.sh" = {
          source = ./dotfiles/scripts/bspwm_hidden_windows.sh;
          executable = true;
        };
        "polybar/scripts/rextie_usd.js" = {
          source = ./dotfiles/scripts/rextie_usd.js;
          executable = true;
        };
        "polybar/scripts/btc_usd.js" = {
          source = ./dotfiles/scripts/btc_usd.js;
          executable = true;
        };
        "polybar/scripts/doge_usd.js" = {
          source = ./dotfiles/scripts/doge_usd.js;
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
