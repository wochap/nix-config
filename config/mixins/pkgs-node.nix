{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [
      deno

      # global nodejs
      nodejs_20
      (yarn.override { nodejs = nodejs_20; })

      # global packages
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.node-gyp-build
      nodePackages.nodemon
      nodePackages.webtorrent-cli

      # others
      netlify-cli
      nodePackages.node2nix
      _custom.customNodePackages."migrate-mongo-9.0.0"

      # nodePackages.sharp-cli
    ];

    home-manager.users.${userName} = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules:$NODE_PATH";
      };

      home.file = {
        ".npmrc".text = ''
          prefix = ''${HOME}/.npm-packages
        '';
      };
    };
  };
}
