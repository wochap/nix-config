{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-web;
in {
  options._custom.programs.lang-web.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bun
      corepack_20 # yarn, pnpm
      dart-sass
      deno
      hugo
      netlify-cli
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.node2nix
      nodePackages.nodemon
      nodePackages.webtorrent-cli
      nodejs_20

      # required by personal nvim config
      nodePackages.ts-node # nvim-dap
      _custom.nodePackages."@styled/typescript-styled-plugin" # nvim-lspconfig
      typescript # nvim-lspconfig
    ];

    _custom.hm = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$HOME/.bun/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules:$NODE_PATH";

        # Fixes `bad interpreter: Text file busy`
        # https://github.com/NixOS/nixpkgs/issues/314713
        UV_USE_IO_URING = "0";
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

