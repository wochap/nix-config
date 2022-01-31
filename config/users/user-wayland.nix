{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./mixins/alacritty
    ./mixins/bat.nix
    ./mixins/default-browser
    ./mixins/discord
    # ./mixins/dunst
    ./mixins/mako
    ./mixins/firefox
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/htop.nix
    ./mixins/kitty
    ./mixins/mime-apps.nix
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/nixos-minimal-wm
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/qt.nix
    ./mixins/redshift.nix
    ./mixins/rofi
    ./mixins/ssh
    ./mixins/thunar
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
    ./mixins/vim
    ./mixins/wofi
    ./mixins/zathura
    ./mixins/zsh
    # ./mixins/android.nix
    # ./mixins/doom-emacs
  ];

  config = {
    home-manager.users.${userName} = {
      xdg.configFile = {
        "electron-flags.conf".source = ./dotfiles/electron-flags.conf;
      };
    };
  };
}
