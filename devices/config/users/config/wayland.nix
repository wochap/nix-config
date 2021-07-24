{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/firefox.nix
    ./mixins/fish
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/zsh.nix
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/eww
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/android.nix
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

      # Setup dotfiles
      home.file = {};
    };
  };
}
