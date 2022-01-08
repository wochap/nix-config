{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  currentDirectory = builtins.toString ./.;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      direnv # auto run nix-shell
    ];

    services.lorri.enable = true;

    home-manager.users.${userName} = {
      home.file = {
        ".envrc".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/.envrc";
        "shell.nix".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/shell.nix";
      };
    };
  };
}
