{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/amfora
    ./mixins/bat.nix
    ./mixins/bottom.nix
    ./mixins/default-browser
    ./mixins/discord
    ./mixins/email
    ./mixins/firefox
    ./mixins/fonts
    ./mixins/fzf.nix
    ./mixins/git
    ./mixins/gnome-keyring.nix
    ./mixins/gpg.nix
    ./mixins/gtk.nix
    ./mixins/htop.nix
    ./mixins/imv.nix
    ./mixins/kanshi.nix
    ./mixins/kitty
    ./mixins/lsd.nix
    ./mixins/mako
    ./mixins/mangadesk
    ./mixins/mime-apps.nix
    ./mixins/mpv
    ./mixins/music
    ./mixins/neofetch
    ./mixins/newsboat
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/nixos-minimal-wm
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/qt.nix
    ./mixins/redshift.nix
    ./mixins/secrets.nix
    ./mixins/ssh
    ./mixins/starship.nix
    ./mixins/syncthing.nix
    ./mixins/thunar
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
    ./mixins/vim
    ./mixins/way-displays
    ./mixins/waybar
    ./mixins/wofi
    ./mixins/youtube.nix
    ./mixins/zathura
    ./mixins/zsh
    # ./mixins/android.nix
    # ./mixins/doom-emacs
    # ./mixins/eww
  ];

  config = {
    home-manager.users.${userName} = {
      xdg.configFile = {
        "electron-flags.conf".source = ./dotfiles/electron-flags.conf;
      };
    };
  };
}
