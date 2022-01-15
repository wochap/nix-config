{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../packages { pkgs = pkgs; lib = lib; };
in
{
  imports = [
    ./mixins/nixos-minimal-wm
    ./mixins/bspwm
    ./mixins/clipmenu.nix
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/redshift.nix
    ./mixins/firefox
    ./mixins/thunar
    ./mixins/discord
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/qt.nix
    ./mixins/picom
    ./mixins/polybar
    ./mixins/zsh
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/eww
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/alacritty
    ./mixins/dunst
    ./mixins/rofi
    ./mixins/neofetch
    # ./mixins/android.nix
    # ./mixins/doom-emacs
    ./mixins/default-browser
    ./mixins/zathura
    ./mixins/nnn
    ./mixins/bat.nix
    ./mixins/htop.nix
  ];

  config = {
    home-manager.users.${userName} = {

      # screenshot utility
      services.flameshot.enable = true;
    };
  };
}
