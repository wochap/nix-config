{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.youtube;
  userName = config._userName;
in {
  options._custom.cli.youtube = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ perl536Packages.WWWYoutubeViewer yt-dlp ];

      shellAliases = {
        # youtube-dl is buggy
        youtube-dl = "yt-dlp";
        yta =
          "youtube-dl --extract-audio --add-metadata --xattrs --embed-thumbnail --audio-quality 0 --audio-format mp3";
        ytv =
          "youtube-dl --merge-output-format mp4 -f 'bestvideo+bestaudio[ext=m4a]/best' --embed-thumbnail --add-metadata";
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile."youtube-viewer/api.json".source =
        ../../../../../secrets/dotfiles/youtube-viewer/api.json;
    };
  };
}
