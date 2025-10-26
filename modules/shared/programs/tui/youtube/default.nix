{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.youtube;
in {
  options._custom.programs.youtube.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [ perl538Packages.WWWYoutubeViewer yt-dlp ];
        shellAliases = {
          # youtube-dl is buggy
          youtube-dl = "yt-dlp";
          # download yt link audio
          yta =
            "yt-dlp --extract-audio --add-metadata --xattrs --embed-thumbnail --audio-quality 0 --audio-format mp3";
          # download yt link video
          ytv =
            "yt-dlp --merge-output-format mp4 -f 'bestvideo+bestaudio[ext=m4a]/best' --embed-thumbnail --add-metadata";
          # download english captions
          ytc =
            "yt-dlp --skip-download --write-sub --write-auto-sub --convert-subs srt --sub-lang en";
        };
      };

      xdg.configFile."youtube-viewer/api.json".source =
        ../../../../../secrets/dotfiles/youtube-viewer/api.json;
    };
  };
}
