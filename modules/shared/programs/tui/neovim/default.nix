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
        neovide # gui

        prevstable-neovim.neovim-remote # required by lazygit
        tree-sitter # required by nvim-treesitter
        luajit # required by neorg

        # required by nvim
        fswatch
        wl-clipboard # required in wayland to copy

        # required by telescope.nvim
        ripgrep
        fd
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
