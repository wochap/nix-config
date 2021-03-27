
{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/git.nix
    ./mixins/zsh.nix
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

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Add config files to home folder
      home.file = lib.mkMerge [
        {
          ".skhdrc".source = ./dotfiles/.skhdrc;
          ".yabairc".source = ./dotfiles/.yabairc;
          ".ssh/config".source = ./dotfiles/ssh-config;
          ".config/kitty/kitty.conf".source = ./dotfiles/kitty-darwin.conf;
          ".vimrc".source = ./mixins/vim/dotfiles/.vimrc;
          ".config/nixpkgs/config.nix".text = ''
            { allowUnfree = true; }
          '';
        }
      ];

      programs.bash.enable = true;

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
