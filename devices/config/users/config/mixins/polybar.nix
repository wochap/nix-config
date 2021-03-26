{ config, pkgs, lib,  ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.gean = lib.mkIf isXorg {
      home.file = {
        ".config/polybar/main.ini".source = ./dotfiles/polybar/main.ini;
        ".config/polybar/scripts/docker_info.sh".source = ./dotfiles/polybar/scripts/docker_info.sh;
        ".config/polybar/scripts/get_gpu_status.sh".source = ./dotfiles/polybar/scripts/get_gpu_status.sh;
        ".config/polybar/scripts/get_spotify_status.sh".source = ./dotfiles/polybar/scripts/get_spotify_status.sh;
        ".config/polybar/scripts/get_vram_status.sh".source = ./dotfiles/polybar/scripts/get_vram_status.sh;
        ".config/polybar/scripts/scroll_spotify_status.sh".source = ./dotfiles/polybar/scripts/scroll_spotify_status.sh;
      };
      services.polybar = {
        enable = true;
        config = ./dotfiles/polybar/config.ini;
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
