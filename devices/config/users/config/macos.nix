
{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/nix-common
    ./mixins/git.nix
    ./mixins/zsh.nix
    ./mixins/vim.nix
    ./mixins/kitty
  ];

  config = {
    home-manager.users.gean = {
      # Add config files to home folder
      home.file = {
        ".skhdrc".source = ./dotfiles-darwin/.skhdrc;
        ".finicky.js".source = ./dotfiles-darwin/.finicky.js;
        ".yabairc".source = ./dotfiles-darwin/.yabairc;
      };
    };
  };
}
