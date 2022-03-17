
{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  imports = [
    ./mixins/alacritty
    ./mixins/amfora
    ./mixins/bat.nix
    ./mixins/bottom.nix
    ./mixins/fonts
    ./mixins/git
    ./mixins/kitty
    ./mixins/lsd.nix
    ./mixins/mangadesk
    ./mixins/newsboat
    ./mixins/nix-common
    ./mixins/nnn
    ./mixins/ptsh
    ./mixins/secrets.nix
    ./mixins/ssh
    ./mixins/user-nix.nix
    ./mixins/vim
    ./mixins/youtube.nix
    ./mixins/zsh
    # ./mixins/htop.nix
    # ./mixins/neofetch
  ];

  config = {
    nix.gc.user = userName;

    home-manager.users.${userName} = {

      programs.gpg.enable = true;

      # Add config files to home folder
      home.file = {
        # ".skhdrc".source = ./dotfiles-darwin/.skhdrc;
        ".finicky.js".source = ./dotfiles-darwin/.finicky.js;
        # ".yabairc".source = ./dotfiles-darwin/.yabairc;
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
