{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  musicDirectory = "${hmConfig.home.homeDirectory}/Music";
in {
  config = {

    home-manager.users.${userName} = {
      home.packages = with pkgs;
        [
          playerctl # media player cli
        ];

      # music cli
      programs.ncmpcpp = {
        enable = true;
        mpdMusicDir = musicDirectory;
        # settings = {};
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
        '';
      };

      # send notification on music change
      services.mpdris2 = {
        enable = true;
        multimediaKeys = true;
        notifications = true;
      };
    };
  };
}
