
{ config, pkgs, lib, ... }:

{
  imports = [
    # ./firefox.nix
    # ./fish.nix
    ./git.nix
    ./zsh.nix
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

      home.sessionVariables = {
        # NIXOS_CONFIG = "/home/gean/nix-config/devices/desktop.nix";
      };

      # Add config files to home folder
      home.file = lib.mkMerge [
        {
          ".ssh/config".source = ./dotfiles/ssh-config;
          ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
          ".vimrc".source = ./dotfiles/.vimrc;
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
