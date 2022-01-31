{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/bat.nix
    ./mixins/bspwm
    ./mixins/clipmenu.nix
    ./mixins/default-browser
    ./mixins/discord
    ./mixins/dunst
    ./mixins/eww
    ./mixins/firefox
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/htop.nix
    ./mixins/kitty
    ./mixins/mime-apps.nix
    ./mixins/neofetch
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/nixos-minimal-wm
    ./mixins/nnn
    ./mixins/picom
    ./mixins/polybar
    ./mixins/ptsh
    ./mixins/qt.nix
    ./mixins/redshift.nix
    ./mixins/rofi
    ./mixins/ssh
    ./mixins/sway
    ./mixins/thunar
    ./mixins/vim
    ./mixins/waybar
    ./mixins/zathura
    ./mixins/zsh
    # ./mixins/android.nix
    # ./mixins/doom-emacs
  ];

  config = {
    home-manager.users.${userName} = {
      xresources.extraConfig = ''
        ${builtins.readFile "${inputs.dracula-xresources}/Xresources"}
      '';
    };
  };
}
