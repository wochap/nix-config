{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-web;
in {
  options._custom.programs.lang-web.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bun
      corepack_24 # yarn, pnpm
      dart-sass
      deno
      hugo
      netlify-cli
      prettier
      eas-cli
      firebase-tools
      http-server
      nodemon
      nodejs_24
      gitleaks
      trufflehog
      semgrep

      # required by personal nvim config
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
          ".npm-packages/.keep".text = "";
          ".npm-packages/lib/.keep".text = "";
        };

        copyFiles.".npmrc".source = ./dotfiles/.npmrc;
      };

      xdg.configFile.".bunfig.toml".source = ./dotfiles/.bunfig.toml;
    };
  };
}

