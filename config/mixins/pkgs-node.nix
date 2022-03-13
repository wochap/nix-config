{ config, pkgs, lib, inputs, ... }:

let localPkgs = import ../packages { inherit pkgs lib; };
in {
  config = {
    environment.systemPackages = with pkgs; [
      # global nodejs
      nodejs-14_x
      (yarn.override { nodejs = nodejs-14_x; })

      # global packages
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.nodemon

      # others
      nodePackages.node2nix

      # nodePackages.sharp-cli
      # unstable.nodePackages_latest.webtorrent-cli
    ];
  };
}
