{ config, pkgs, lib,  ... }:

let
  localPkgs = import ../../../../packages { pkgs = pkgs; lib = lib; };
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/config/mixins/polybar";
  customPolybar = pkgs.polybar.override {
    alsaSupport = true;
    mpdSupport = true;
    pulseSupport = true;
  };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        customPolybar
        localPkgs.zscroll # scroll text in shells
      ];
      sessionVariables = {
        # POLYBAR_HEIGHT = 48 + 3 * 2
        POLYBAR_HEIGHT = "54";
        POLYBAR_MARGIN = "25";
      };
      etc = {
        "scripts/polybar-toggle.sh" = {
          source = ./scripts/polybar-toggle.sh;
          mode = "0755";
        };
        "scripts/polybar-start.sh" = {
          source = ./scripts/polybar-start.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "polybar/config.ini".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config.ini";
        "polybar/main.ini".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/main.ini";
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
    };
  };
}
