{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  isXorg = config._displayServer == "xorg";
  isHidpi = config._isHidpi;
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  imports = [
    ./mixins/nix-common
    ./mixins/nixos
    ./mixins/nixos-minimal-wm.nix
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
    ./mixins/android.nix
    ./mixins/doom-emacs
    ./mixins/default-browser
    ./mixins/zathura
    ./mixins/nnn
    ./mixins/xob
  ];

  config = {
    home-manager.users.${userName} = {
      # Setup dotfiles
      home.file = {
        ".config/betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;

        # Fix cursor theme
        ".icons/default".source = "${localPkgs.bigsur-cursors}/share/icons/bigsur-cursors";
      };

      xsession.pointerCursor = {
        package = localPkgs.bigsur-cursors;
        defaultCursor = "left_ptr";
        name = "bigsur-cursors";
        size = if isHidpi then 40 else 32;
      };

      # screenshot utility
      services.flameshot.enable = true;
    };
  };
}
