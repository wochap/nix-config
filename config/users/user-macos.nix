
{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./mixins/alacritty
    # ./mixins/amfora
    ./mixins/bat.nix
    ./mixins/fonts
    ./mixins/git.nix
    ./mixins/kitty
    ./mixins/nix-common
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/ssh
    ./mixins/user-nix.nix
    ./mixins/vim
    ./mixins/zsh
    # ./mixins/htop.nix
    # ./mixins/neofetch
  ];

  config = {
    home-manager.users.${userName} = {
      nix.gc.user = userName;

      # Add config files to home folder
      home.file = {
        ".skhdrc".source = ./dotfiles-darwin/.skhdrc;
        ".finicky.js".source = ./dotfiles-darwin/.finicky.js;
        ".yabairc".source = ./dotfiles-darwin/.yabairc;
      };

      programs.bash.bashrcExtra = ''
        export ANDROID_HOME=$HOME/Library/Android/sdk
        export PATH=$PATH:$ANDROID_HOME/emulator
        export PATH=$PATH:$ANDROID_HOME/tools
        export PATH=$PATH:$ANDROID_HOME/tools/bin
        export PATH=$PATH:$ANDROID_HOME/platform-tools
        export LANG=en_US.UTF-8
      '';
    };
  };
}
