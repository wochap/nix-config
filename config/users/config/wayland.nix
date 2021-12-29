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
    ./mixins/zsh
    ./mixins/mime-apps.nix
    ./mixins/vim
    ./mixins/ptsh
    ./mixins/kitty
    ./mixins/alacritty
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

      home.sessionVariables = {
        PATH = "$HOME/.npm-packages/bin:$PATH";
        NODE_PATH = "$HOME/.npm-packages/lib/node_modules";
      };

      home.file = {
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
        ".npmrc".source = ./dotfiles/.npmrc;
      };
    };
  };
}
