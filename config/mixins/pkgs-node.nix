{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [
      deno

      # global nodejs
      nodejs-14_x
      (yarn.override { nodejs = nodejs-14_x; })

      # global packages
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.node-gyp-build
      nodePackages.nodemon

      # others
      netlify-cli
      nodePackages.node2nix

      # nodePackages.sharp-cli
      # unstable.nodePackages_latest.webtorrent-cli
    ];

    home-manager.users.${userName} = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules";
      };

      home.file = {
        ".npmrc".text = ''
          prefix = ''${HOME}/.npm-packages
        '';
      };
    };
  };
}
