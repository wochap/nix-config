{ config, lib, pkgs, inputs, ... }:

let cfg = config._custom.programs.neovim;
in {
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ];

    _custom.programs.neovim = {
      setBuildEnv = true;
      withBuildTools = true;
      package = pkgs.neovim-unwrapped;
    };

    environment = {
      systemPackages = with pkgs; [
        fswatch
        prevstable-neovim.neovim-remote
        neovide

        # required in wayland to copy
        wl-clipboard

        # required by mason
        lua54Packages.luarocks # HACK: it should be necessary here
        go

        # required by peek.nvim
        deno

        # required by treesitter
        tree-sitter

        # required by nvim-lint
        statix

        # required by conform.nvim
        nixfmt

        # required by telescope
        ripgrep
        fd

        # required by nvim-dap
        unstable.nodePackages.ts-node

        # required by nvim-lspconfig
        unstable.typescript
        _custom.nodePackages."@styled/typescript-styled-plugin"
      ];
    };

    _custom.hm = {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      programs.zsh.shellAliases = {
        nvd = ''neovide "$@"'';
        nv = ''run-without-kpadding nvim "$@"'';
        lc = "run-without-kpadding nvim leetcode.nvim";
        lcd = "neovide leetcode.nvim";
      };

      xdg.desktopEntries = {
        leetcode = {
          name = "LeetCode";
          exec = "neovide leetcode.nvim";
        };
      };
    };
  };
}
