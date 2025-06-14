{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-web;
  inherit (config._custom.globals) configDirectory;
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
      nodePackages.prettier
      nodePackages.eas-cli
      nodePackages.firebase-tools
      nodePackages.gulp
      nodePackages.http-server
      nodePackages.node2nix
      nodePackages.nodemon
      _custom.nodePackages."webtorrent-cli-4.1.0"
      nodejs_20

      # required by personal nvim config
      nodePackages.ts-node # nvim-dap
      _custom.nodePackages."@styled/typescript-styled-plugin" # nvim-lspconfig
      typescript # nvim-lspconfig
    ];

    _custom.hm = {
      home = {
        sessionPath = [ "$HOME/.npm-packages/bin" "$HOME/.bun/bin" ];

        sessionVariables = {
          NODE_PATH = "$HOME/.npm-packages/lib/node_modules:$NODE_PATH";

          # Fixes `bad interpreter: Text file busy`
          # https://github.com/NixOS/nixpkgs/issues/314713
          UV_USE_IO_URING = "0";
        };

        file = {
          ".npmrc".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/.npmrc;
          ".npm-packages/.keep".text = "";
          ".npm-packages/lib/.keep".text = "";
        };
      };

      xdg.configFile.".bunfig.toml".source = ./dotfiles/.bunfig.toml;
    };
  };
}

