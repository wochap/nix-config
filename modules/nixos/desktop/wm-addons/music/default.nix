{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.music;
  inherit (config._custom.globals)
    userName themeColorsLight themeColorsDark preferDark;
  hmConfig = config.home-manager.users.${userName};
  musicDirectory = "${hmConfig.home.homeDirectory}/Music";

  catppuccin-cava-light-theme = ''
    ${lib.fileContents ./dotfiles/cava/config}
    ${lib.fileContents
    "${inputs.catppuccin-cava}/themes/${themeColorsLight.flavour}-transparent.cava"}
  '';
  catppuccin-cava-dark-theme = ''
    ${lib.fileContents ./dotfiles/cava/config}
    ${lib.fileContents
    "${inputs.catppuccin-cava}/themes/${themeColorsDark.flavour}-transparent.cava"}
  '';
in {
  options._custom.desktop.music.enable = lib.mkEnableOption { };

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
        "cava/config" = {
          text = if preferDark then
            catppuccin-cava-dark-theme
          else
            catppuccin-cava-light-theme;
          force = true;
        };
        "cava/config-light".text = catppuccin-cava-light-theme;
        "cava/config-dark".text = catppuccin-cava-dark-theme;
        "ncmpcpp/config".source = ./dotfiles/ncmpcpp/config;
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
