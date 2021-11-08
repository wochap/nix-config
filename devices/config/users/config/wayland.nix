{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
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
    # ./mixins/android.nix
    ./mixins/default-browser
    ./mixins/zathura
  ];

  config = {
    home-manager.users.${userName} = {};
  };
}
