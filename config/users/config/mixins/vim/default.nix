{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        neovim
        neovim-qt # better fractional scaling support
        shellcheck

        # required by telescope
        ripgrep
        fd

        # required by null-ls
        nodePackages.eslint_d
        nodePackages.vscode-css-languageserver-bin
        nodePackages.vscode-html-languageserver-bin

        # required by LSP
        nodePackages.typescript
        nodePackages.typescript-language-server
      ];
      shellAliases = {
        nv = "nvim";
      };
    };

    home-manager.users.${userName} = {
      home.file = {
        ".vimrc".source = ./dotfiles/.vimrc;
      };

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
