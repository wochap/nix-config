{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.vim;
  userName = config._userName;
in {
  options._custom.tui.vim = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home.file = { ".vimrc".source = ./dotfiles/.vimrc; };

      programs.vim = {
        enable = true;
        settings = {
          relativenumber = true;
          number = true;
        };
      };
    };
  };
}
