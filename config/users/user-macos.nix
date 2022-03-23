{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  imports = [
    ./mixins/alacritty
    ./mixins/amfora
    ./mixins/bat.nix
    ./mixins/bottom.nix
    ./mixins/fonts
    ./mixins/fzf.nix
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
    ./mixins/starship.nix
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

      home.sessionVariables = { LANG = "en_US.UTF-8"; };

      # Add config files to home folder
      home.file = {
        ".finicky.js".source = ./dotfiles-darwin/.finicky.js;
        # ".skhdrc".source = ./dotfiles-darwin/.skhdrc;
        # ".yabairc".source = ./dotfiles-darwin/.yabairc;
      };

    };
  };
}
