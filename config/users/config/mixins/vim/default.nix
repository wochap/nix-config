{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      neovim
    ];

    home-manager.users.${userName} = {
      home.file = {
        ".vimrc".source = ./dotfiles/.vimrc;
      };

      programs.vim = {
        enable = true;
        settings = {
          relativenumber = true;
          number = true;
        };
      };
    };
  };
}
