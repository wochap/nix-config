{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  imports = [
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/redshift.nix
    ./mixins/firefox.nix
    ./mixins/fish
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/picom
    ./mixins/polybar
    ./mixins/zsh.nix
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/eww
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/dunst
    ./mixins/rofi
    # ./mixins/android.nix
    ./mixins/doom-emacs
    ./mixins/default-browser
    ./mixins/zathura
    ./mixins/nnn
    ./mixins/xob
  ];

  config = {
    home-manager.users.${userName} = {
      # Setup dotfiles
      xdg.configFile = {
        "betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;
      };

      # screenshot utility
      services.flameshot.enable = true;
    };
  };
}
