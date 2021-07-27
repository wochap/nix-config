{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/firefox.nix
    ./mixins/fish
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/zsh.nix
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/android.nix
  ];

  config = {
    home-manager.users.gean = {};
  };
}
