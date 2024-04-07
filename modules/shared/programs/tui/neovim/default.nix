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
        wl-clipboard # required in wayland to copy
        tree-sitter # required by nvim-treesitter

        # required by mason.nvim
        # NOTE: it shouldn't be necessary here
        lua54Packages.luarocks

        # required by telescope
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
