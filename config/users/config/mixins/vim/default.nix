{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
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
        neovide
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
        nixfmt
        nodePackages.eslint_d
        python39Packages.pylint
        shellcheck
        shfmt
        statix
        stylua

        # required by lspconfig
        clang-tools
        flow
        localPkgs.customNodePackages."@tailwindcss/language-server"
        localPkgs.customNodePackages.cssmodules-language-server
        localPkgs.customNodePackages.emmet-ls
        nodePackages.bash-language-server
        nodePackages.svelte-language-server
        nodePackages.vscode-langservers-extracted
        rnix-lsp
        # localPkgs.customNodePackages.typescript
        # localPkgs.customNodePackages.typescript-language-server
        # npm i typescript typescript-language-server -g
      ] ++ (if (!isDarwin) then [
        sumneko-lua-language-server
      ] else []);
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
