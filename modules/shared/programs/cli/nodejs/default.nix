{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.nodejs;
in {
  options._custom.programs.nodejs.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bun
      deno

      # global nodejs
      nodejs_20
      (yarn.override { nodejs = nodejs_20; })

      # global packages
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.nodemon
      nodePackages.pnpm
      nodePackages.webtorrent-cli

      # others
      netlify-cli
      nodePackages.node2nix

      # nodePackages.sharp-cli
    ];

    _custom.hm = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$HOME/.bun/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules:$NODE_PATH";
      };

      home.file = {
        ".npmrc".source = ./dotfiles/.npmrc;
        ".npm-packages/.keep".text = "";
        ".npm-packages/lib/.keep".text = "";
      };

      xdg.configFile.".bunfig.toml".source = ./dotfiles/.bunfig.toml;
    };
  };
}

