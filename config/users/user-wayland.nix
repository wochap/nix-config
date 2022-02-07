{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/way-displays
    ./mixins/bat.nix
    ./mixins/default-browser
    ./mixins/discord
    ./mixins/firefox
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/htop.nix
    ./mixins/kanshi.nix
    ./mixins/kitty
    ./mixins/mako
    ./mixins/mime-apps.nix
    ./mixins/neofetch
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/nixos-minimal-wm
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/qt.nix
    ./mixins/redshift.nix
    ./mixins/ssh
    ./mixins/thunar
    ./mixins/user-nix.nix
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
    ./mixins/user-nixos.nix
    ./mixins/vim
    ./mixins/waybar
    ./mixins/wofi
    ./mixins/zathura
    ./mixins/zsh
    # ./mixins/eww
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
