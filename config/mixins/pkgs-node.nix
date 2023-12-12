{ config, pkgs, ... }:

let userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [
      unstable.bun
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

    home-manager.users.${userName} = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$HOME/.bun/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules:$NODE_PATH";
      };

      home.file = {
        ".npmrc".text = ''
          prefix = ''${HOME}/.npm-packages
        '';
      };

      xdg.configFile.".bunfig.toml".text = ''
        [install]
        # where `bun install --global` installs packages
        globalDir = "~/.bun/install/global"

        # where globally-installed package bins are linked
        globalBinDir = "~/.bun/bin"

        [install.cache]
        # the directory to use for the cache
        dir = "~/.bun/install/cache"
      '';
    };
  };
}
