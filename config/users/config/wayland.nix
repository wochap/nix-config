{ config, pkgs, lib, ... }:

let
  userName = config._userName;
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
    ./mixins/zsh.nix
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/dunst
    ./mixins/rofi
    # ./mixins/android.nix
    ./mixins/default-browser
    ./mixins/zathura
    # ./mixins/doom-emacs
    # ./mixins/nnn
  ];

  config = {
    home-manager.users.${userName} = {
      xdg.configFile = {
        "electron-flags.conf".source = ./dotfiles/electron-flags.conf;
        "discord/settings.json".source = ./dotfiles/discord-settings.json;
      };
    };
  };
}
