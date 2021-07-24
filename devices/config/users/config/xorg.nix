{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
  isHidpi = config._isHidpi;
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  imports = [
    ./mixins/nix-common
    ./mixins/nixos
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
      home.file = {
        ".config/betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;

        # Fix cursor theme
        ".icons/default".source = "${localPkgs.bigsur-cursors}/share/icons/bigsur-cursors";
      };

      xresources.properties = lib.mkIf isHidpi {
        "Xcursor.size" = 40;
      };

      services.redshift = {
        enable = true;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };

      # screenshot utility
      services.flameshot.enable = true;
    };
  };
}
