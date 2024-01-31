{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.music;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  musicDirectory = "${hmConfig.home.homeDirectory}/Music";
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (pkgs._custom.runtimePath config._custom.globals.configDirectory path);
in {
  options._custom.wm.music = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    # required by cava
    boot.kernelModules = [ "snd_aloop" ];

    home-manager.users.${userName} = {
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
        "cava/config".source = relativeSymlink ./dotfiles/cava/config;

        # "ncmpcpp/ncmpcpp-ueberzug/fallback.jpg".source =
        #   ../../../mixins/lightdm/assets/wallpaper.jpg;
        "ncmpcpp/config".source = relativeSymlink ./dotfiles/ncmpcpp/config;
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
