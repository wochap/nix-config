
{ config, pkgs, lib, ... }:

{
  imports = [
    ./mixins/nix-common
    ./mixins/git.nix
    ./mixins/zsh.nix
    ./mixins/vim
    ./mixins/kitty
    ./mixins/ptsh
  ];

  config = {
    home-manager.users.gean = {
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
      '';
    };
  };
}
