
{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./mixins/nix-common
    ./mixins/git.nix
    ./mixins/zsh
    ./mixins/vim
    ./mixins/kitty
    ./mixins/ptsh
    ./mixins/nnn
  ];

  config = {
    home-manager.users.${userName} = {
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
