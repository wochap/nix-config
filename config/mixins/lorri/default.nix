{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/mixins/lorri";
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        direnv # auto run nix-shell
      ];

    services.lorri.enable = true;

    home-manager.users.${userName} = {
      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules";
      };

      xdg.configFile = {
        "direnv/direnv.toml".source = ./dotfiles/direnv.toml;
      };

      home.file = {
        ".npmrc".source = ./dotfiles/.npmrc;
        ".envrc".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/.envrc";
        "shell.nix".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/shell.nix";
      };
    };
  };
}
