{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/music";
  musicDirectory = "${hmConfig.home.homeDirectory}/Music";
in {
  config = {
    # required by cava
    boot.kernelModules = [ "snd_aloop" ];

    home-manager.users.${userName} = {
      home.packages = with pkgs; [
        cava
        mpc_cli
        ncmpcpp
        playerctl # media player cli
        sacad
        ueberzug
      ];

      xdg.configFile = {
        # "ncmpcpp/ncmpcpp-ueberzug/fallback.jpg".source =
        #   ../../../mixins/lightdm/assets/wallpaper.jpg;

        # cava audio visualizer
        "cava/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/cava/config";

        # ncmpcpp config
        "ncmpcpp/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/ncmpcpp/config";
        "ncmpcpp/ncmpcpp-ueberzug/ncmpcpp_cover_art.sh" = {
          recursive = true;
          executable = true;
          source = ./dotfiles/ncmpcpp/ncmpcpp-ueberzug/ncmpcpp_cover_art.sh;
        };
        "ncmpcpp/ncmpcpp-ueberzug/ncmpcpp-ueberzug" = {
          recursive = true;
          executable = true;
          source = ./dotfiles/ncmpcpp/ncmpcpp-ueberzug/ncmpcpp-ueberzug.sh;
        };
      };

      # media keys
      services.playerctld.enable = true;

      # music player daemon
      services.mpd = {
        enable = true;
        musicDirectory = musicDirectory;
        network = {
          # listenAddress = "any";
          port = 6600;
          startWhenNeeded = true;
        };
        extraConfig = ''
          restore_paused "yes"

          audio_output {
            type "pipewire"
            name "My PipeWire Output"
          }

          audio_output {
            type "fifo"
            name "my_fifo"
            path "/tmp/mpd.fifo"
            format "44100:16:2"
          }
        '';
      };

      # send notification on music change
      services.mpdris2 = {
        enable = true;
        multimediaKeys = true;
        notifications = false;
      };
    };
  };
}
