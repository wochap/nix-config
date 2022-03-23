{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/amfora
    ./mixins/android.nix
    ./mixins/autorandr
    ./mixins/bat.nix
    ./mixins/bottom.nix
    ./mixins/bspwm
    ./mixins/clipmenu.nix
    ./mixins/default-browser
    ./mixins/discord
    ./mixins/dunst
    ./mixins/email
    ./mixins/eww
    ./mixins/firefox
    ./mixins/fonts
    ./mixins/fzf.nix
    ./mixins/git
    ./mixins/gnome-keyring.nix
    ./mixins/gpg.nix
    ./mixins/gtk.nix
    ./mixins/htop.nix
    ./mixins/imv.nix
    ./mixins/kitty
    ./mixins/lsd.nix
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
    ./mixins/picom
    ./mixins/polybar
    ./mixins/ptsh
    ./mixins/qt.nix
    ./mixins/redshift.nix
    ./mixins/rofi
    ./mixins/secrets.nix
    ./mixins/ssh
    ./mixins/starship.nix
    ./mixins/syncthing.nix
    ./mixins/thunar
    ./mixins/user-nix.nix
    ./mixins/user-nixos.nix
    ./mixins/vim
    ./mixins/xsettingsd
    ./mixins/youtube.nix
    ./mixins/zathura
    ./mixins/zsh
    # ./mixins/exa.nix
    # ./mixins/doom-emacs
  ];

  config = {
    home-manager.users.${userName} = {
      imports = [ ./modules/symlinks.nix ];

      config = {
        xresources.extraConfig = ''
          ${builtins.readFile "${inputs.dracula-xresources}/Xresources"}
        '';
      };
    };
  };
}
