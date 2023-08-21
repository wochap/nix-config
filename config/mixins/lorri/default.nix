{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/mixins/lorri";
  # TODO: uncomment after electron fixes
  # newer versions of direnv, auto load .env files
  # customDirenv = pkgs.direnv.overrideAttrs(o: {
  #   src = pkgs.fetchFromGitHub {
  #     repo = "direnv";
  #     owner = "direnv";
  #     rev = "3c84231d9781ef1dd3df81a7b2de52e1dad58f62";
  #     sha256 = "sha256-dokZDGs09Q/P3QN3gfnUB25vim/+VN5xxKt9FkFfTb8=";
  #   };
  #   # temporarily disable tests, check if they can be reenabled with the next release
  #   doCheck = true;
  # });

in {
  config = {
    environment.systemPackages = with pkgs;
      [
        # customDirenv # auto run nix-shell
        direnv
      ];

    services.lorri.enable = true;

    home-manager.users.${userName} = {
      xdg.configFile = {
        "direnv/direnv.toml".source = ./dotfiles/direnv.toml;
      };

      home.file = {
        # ".envrc".source =
        #   mkOutOfStoreSymlink "${currentDirectory}/dotfiles/.envrc";
        # "shell.nix".source =
        #   mkOutOfStoreSymlink "${currentDirectory}/dotfiles/shell.nix";
      };
    };
  };
}
