{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/amfora
    ./mixins/bat.nix
    ./mixins/bottom.nix
    ./mixins/default-browser
    ./mixins/discord
    ./mixins/firefox
    ./mixins/fonts
    ./mixins/fzf.nix
    ./mixins/gammastep.nix
    ./mixins/git
    ./mixins/gnome-keyring.nix
    ./mixins/gpg.nix
    ./mixins/htop.nix
    ./mixins/imv.nix
    ./mixins/kitty
    ./mixins/lsd.nix
    ./mixins/mangadesk
    ./mixins/mangal
    ./mixins/mpv
    ./mixins/music
    ./mixins/neofetch
    ./mixins/newsboat
    ./mixins/nixos
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/secrets.nix
    ./mixins/ssh
    ./mixins/starship.nix
    ./mixins/syncthing.nix
    ./mixins/thunar
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
    ./mixins/vim
    ./mixins/youtube.nix
    ./mixins/zathura
    ./mixins/zsh
  ];

  config = {
    home-manager.users.${userName} = { imports = [ ./modules/symlinks.nix ]; };
  };
}
