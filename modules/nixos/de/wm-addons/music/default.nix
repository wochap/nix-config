{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.music;
  inherit (config._custom.globals) userName configDirectory;
  hmConfig = config.home-manager.users.${userName};
  musicDirectory = "${hmConfig.home.homeDirectory}/Music";
  inherit (lib._custom) relativeSymlink;
in {
  options._custom.wm.music.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # required by cava
    boot.kernelModules = [ "snd_aloop" ];

    _custom.hm = {
      home.packages = with pkgs; [
        cava # visualizer
        mpc_cli # mpd cli
        (pkgs.ncmpcpp.override {
          visualizerSupport = true;
          clockSupport = true;
          taglibSupport = true;
        })
        playerctl # media player cli
        sacad # search and download album covert
        # ueberzugpp
      ];

      xdg.configFile = {
        "cava/config".source =
          relativeSymlink configDirectory ./dotfiles/cava/config;

        "ncmpcpp/config".source =
          relativeSymlink configDirectory ./dotfiles/ncmpcpp/config;
      };

      # media keys
      services.playerctld.enable = true;

      # music player daemon
      services.mpd = {
        enable = true;
        inherit musicDirectory;
        extraArgs = [ "--verbose" ];
        network = {
          listenAddress = "127.0.0.1";
          port = 6600;
          startWhenNeeded = false;
        };
        extraConfig = ''
          auto_update "yes"
          restore_paused "yes"

          audio_output {
            type "pipewire"
            name "PipeWire output"
          }

          audio_output {
            name "Visualizer feed"
            type "fifo"
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
