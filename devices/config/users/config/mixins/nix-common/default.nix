{ config, pkgs, lib, ... }:

{
  config = {
    home-manager.users.gean = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Setup dotfiles
      home.file = {
        ".ssh/config".source = ./dotfiles/ssh-config;
        "Pictures/backgrounds/default.jpeg".source = ../../../assets/wallpaper.jpeg;
        ".config/nixpkgs/config.nix".text = ''
          { allowUnfree = true; }
        '';
      };

      programs.bash.enable = true;
    };
  };
}
