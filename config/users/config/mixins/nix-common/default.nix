{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Setup dotfiles
      home.file = {
        ".ssh/config".source = ./dotfiles/ssh-config;
        ".config/nixpkgs/config.nix".text = ''
          { allowUnfree = true; }
        '';
      };

      programs.bash.enable = true;
    };
  };
}
