{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config._custom.globals) configDirectory;
  cfg = config._custom.programs.lang-web;
in
{
  options._custom.programs.lang-web.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        bun = prev.bun.overrideAttrs (old: rec {
          version = "1.3.14";
          src = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
            hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
          };
        });
      })
    ];

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
        sessionPath = [
          "$HOME/.npm-packages/bin"
          "$HOME/.cache/.bun/bin"
        ];

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

      xdg.configFile.".bunfig.toml".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/.bunfig.toml;
    };
  };
}
