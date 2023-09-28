{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
  # extraPackages = with pkgs; [
  #   _custom.customNodePackages.typescript
  #   _custom.customNodePackages.typescript-language-server
  # ];
  # extraMakeWrapperArgs = ''--suffix PATH : "${lib.makeBinPath extraPackages}"'';
in {
  config = {
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     # https://github.com/neovide/neovide/compare/0.11.1...wochap:fix_font_symbols_height.patch
    #     neovide = prev.neovide.overrideAttrs (drv: rec {
    #       patches = [
    #         (prev.fetchpatch {
    #           url =
    #             "https://github.com/neovide/neovide/compare/0.11.1...wochap:fix_font_symbols_height.patch";
    #           sha256 = "sha256-uZnqwcGiCIUQ7b2lcj4W0AfYNg61IwbgoE7/sJeXkH0=";
    #         })
    #       ];
    #     });
    #   })
    # ];

    environment = {
      systemPackages = with pkgs;
        [
          # oni2
          # neovim-qt # better fractional scaling support
          # uivonim

          # TODO: passextraMakeWrapperArgs?
          prevstable-neovim.neovim
          prevstable-neovim.neovim-remote

          # required by https://github.com/toppair/peek.nvim
          deno
          # webkitgtk

          # required by treesitter
          tree-sitter

          # required by telescope
          ripgrep
          fd

          # required by null-ls
          _custom.customNodePackages."@fsouza/prettierd"
          _custom.customNodePackages.markdownlint
          _custom.customNodePackages.stylelint
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
          _custom.customNodePackages."@tailwindcss/language-server"
          _custom.customNodePackages.cssmodules-language-server
          _custom.customNodePackages."@olrtg/emmet-language-server"
          nodePackages.bash-language-server
          nodePackages.svelte-language-server
          nodePackages.vscode-langservers-extracted
          rnix-lsp
          # _custom.customNodePackages.typescript
          # _custom.customNodePackages.typescript-language-server
          # npm i typescript typescript-language-server -g

          # required by nvim-dap
          _custom.customNodePackages.ts-node
        ] ++ (if (!isDarwin) then [
          unstable.neovide

          # required by lspconfig
          sumneko-lua-language-server
        ] else
          [ ]);
      shellAliases = {
        # HACK: remove padding inside kitty
        nv =
          "[[ -n $KITTY_PID ]] && (kitty @ set-spacing padding=0 && nvim && kitty @ set-spacing padding=7) || nvim";
      };
    };

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
