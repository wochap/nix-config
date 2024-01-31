{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.tui.neovim;
  isDarwin = pkgs.stdenv.isDarwin;
  userName = config._userName;
in {
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    _custom.tui.neovim.setBuildEnv = true;
    _custom.tui.neovim.withBuildTools = true;

    nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ];

    environment = {
      systemPackages = with pkgs;
        [
          prevstable-neovim.neovim-remote

          # custom
          fswatch

          # required by mason
          lua54Packages.luarocks # HACK: it should be necessary here
          go

          # required by https://github.com/toppair/peek.nvim
          deno

          # required by treesitter
          tree-sitter

          # required by null-ls
          deadnix
          nixfmt
          statix

          # required by telescope
          ripgrep
          fd

          # required by nvim-dap
          _custom.customNodePackages.ts-node

          # required by nvim-lspconfig
          # config.nur.repos.Freed-Wu.autotools-language-server
          _custom.customNodePackages.typescript
          _custom.customNodePackages."@styled/typescript-styled-plugin"
        ] ++ (lib.optionals (!isDarwin) [ unstable.neovide ]);
    };

    programs.zsh.shellAliases = {
      nv = ''run-without-kpadding nvim "$@"'';
      lc = "run-without-kpadding nvim leetcode.nvim";
    };

    home-manager.users.${userName} = {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
  };
}
