{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.music;
  inherit (config._custom.globals)
    userName
    themeColorsLight
    themeColorsDark
    preferDark
    ;
  hmConfig = config.home-manager.users.${userName};

  catppuccin-cava-light-theme = ''
    ${lib.fileContents ./dotfiles/cava/config}
    ${lib.fileContents "${inputs.catppuccin-cava}/themes/${themeColorsLight.flavour}-transparent.cava"}
  '';
  catppuccin-cava-dark-theme = ''
    ${lib.fileContents ./dotfiles/cava/config}
    ${lib.fileContents "${inputs.catppuccin-cava}/themes/${themeColorsDark.flavour}-transparent.cava"}
  '';
in
{
  options._custom.desktop.music = {
    enable = lib.mkEnableOption { };
    musicDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${hmConfig.home.homeDirectory}/Music";
      defaultText = lib.literalExpression ''"''${home.homeDirectory}/Music"'';
      description = ''
        Directory mpd plays from. mpd has a single music directory; add
        other folders with extraDirectories.
      '';
    };
    extraDirectories = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        library = "/mnt/storage/media-server/media/music";
      };
      description = ''
        Folders symlinked into musicDirectory under the attribute name, so
        mpd (which follows symlinks out of its music directory) plays them
        too.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # home.file can only place the links below the home directory.
        assertion =
          cfg.extraDirectories == { } || lib.hasPrefix "${hmConfig.home.homeDirectory}/" cfg.musicDirectory;
        message = "_custom.desktop.music.extraDirectories needs musicDirectory below the home directory.";
      }
    ];

    # required by cava
    boot.kernelModules = [ "snd_aloop" ];

    _custom.hm = {
      home.packages = with pkgs; [
        cava # visualizer
        mpc # mpd cli
        playerctl # media player cli
        sacad # search and download album covert
        # ueberzugpp
      ];

      xdg.configFile = {
        "cava/config" = {
          text = if preferDark then catppuccin-cava-dark-theme else catppuccin-cava-light-theme;
          force = true;
        };
        "cava/config-light".text = catppuccin-cava-light-theme;
        "cava/config-dark".text = catppuccin-cava-dark-theme;

        "rmpc/config.ron".source = ./dotfiles/rmpc/config.ron;
      };

      home.file = lib.mapAttrs' (
        name: path:
        lib.nameValuePair "${lib.removePrefix "${hmConfig.home.homeDirectory}/" cfg.musicDirectory}/${name}"
          {
            source = hmConfig.lib.file.mkOutOfStoreSymlink path;
          }
      ) cfg.extraDirectories;

      programs.rmpc.enable = true;

      # media keys
      services.playerctld.enable = true;

      # music player daemon
      services.mpd = {
        enable = true;
        inherit (cfg) musicDirectory;
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
