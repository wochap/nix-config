{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../../packages { pkgs = pkgs; lib = lib; };
  # extraPackages = with pkgs; [
  #   localPkgs.customNodePackages.typescript
  #   localPkgs.customNodePackages.typescript-language-server
  # ];
  # extraMakeWrapperArgs = ''--suffix PATH : "${lib.makeBinPath extraPackages}"'';
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # oni2
        # neovide
        # neovim-qt # better fractional scaling support
        # uivonim

        # neovim # TODO: passextraMakeWrapperArgs?
        neovim-nightly

        # required by treesitter
        tree-sitter

        # required by telescope
        ripgrep
        fd

        # required by null-ls
        localPkgs.customNodePackages."@fsouza/prettierd"
        localPkgs.customNodePackages.markdownlint
        localPkgs.customNodePackages.stylelint
        lua51Packages.luacheck
        nodePackages.eslint_d
        python39Packages.pylint
        shellcheck
        shfmt
        stylua

        # required by lspconfig
        localPkgs.customNodePackages."@tailwindcss/language-server"
        localPkgs.customNodePackages.emmet-ls
        # npm i typescript typescript-language-server -g
        # localPkgs.customNodePackages.typescript
        # localPkgs.customNodePackages.typescript-language-server
        nodePackages.bash-language-server
        nodePackages.svelte-language-server
        nodePackages.vscode-langservers-extracted
        sumneko-lua-language-server
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
