{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        perl534Packages.WWWYoutubeViewer
        youtube-dl
      ];
    };

    home-manager.users.${userName} = {

      xdg.configFile."youtube-viewer/api.json".source =
        ../../../secrets/dotfiles/youtube-viewer/api.json;
    };
  };
}
