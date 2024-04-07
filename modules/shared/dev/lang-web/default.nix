{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-web;
in {
  options._custom.dev.lang-web.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bun
      corepack_20 # yarn, pnpm
      deno
      netlify-cli
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.node2nix
      nodePackages.nodemon
      nodePackages.webtorrent-cli
      nodejs_20
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

