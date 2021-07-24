
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
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "21.03";

      # Add config files to home folder
      home.file = {
        ".skhdrc".source = ./dotfiles-darwin/.skhdrc;
        ".finicky.js".source = ./dotfiles-darwin/.finicky.js;
        ".yabairc".source = ./dotfiles-darwin/.yabairc;
      };
    };
  };
}
