{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.programs.neovim;
  inherit (config._custom.globals) configDirectory;
in {
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    _custom.programs.neovim = {
      setBuildEnv = true;
      withBuildTools = true;
      package = pkgs.prevstable-neovim.neovim-unwrapped;
      # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    };

    environment = {
      systemPackages = with pkgs; [
        nixpkgs-master.neovide # gui

        marksman # required by nvim-lspconfig
        _custom.neovim-remote # required by lazygit
        tree-sitter # required by nvim-treesitter

        # required by nvim
        fswatch
        wl-clipboard # required in wayland to copy

        # required by telescope.nvim
        fd
        ripgrep
      ];
    };

    _custom.hm = {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      xdg.desktopEntries = {
        leetcode = {
          name = "LeetCode";
          exec = "neovide leetcode.nvim";
        };
      };

      programs.git.extraConfig.core.editor = "nvim";

      programs.lazygit.settings.os = {
        editPreset = "nvim-remote";
        edit = # sh
          "[ -z $NVIM ] && (nvim -- {{filename}}) || (nvr -l --remote-silent +'lua Snacks.lazygit()' +'WindowPicker {{filename}}')";
        editAtLine = # sh
          "[ -z $NVIM ] && (nvim +{{line}} -- {{filename}}) || (nvr -l --remote-silent +'lua Snacks.lazygit()' +'WindowPicker {{filename}}' +{{line}})";
        editAtLineAndWait = # sh
          "[ -z $NVIM ] && (nvim +{{line}} {{filename}}) || (nvr -l --remote-wait-silent +'lua Snacks.lazygit()' +'WindowPicker {{filename}}' +{{line}})";
      };

      programs.zsh.shellAliases = {
        nvd = ''neovide "$@"'';
        nv = ''run-without-kpadding nvim "$@"'';
        lc = "run-without-kpadding nvim leetcode.nvim";
        lcd = "neovide leetcode.nvim";
      };

      xdg.configFile."neovide/config.toml".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/neovide.toml;

      home.file.".config/zsh/.zshrc".text = lib.mkAfter # zsh
        ''
          # Prevent nested nvim in nvim terminal
          if [ -n "$NVIM" ]; then
            alias nvim='nvr -l --remote-wait-silent "$@"'
            alias nv='nvr -l --remote-wait-silent "$@"'
            export VISUAL="nvr -l --remote-wait-silent"
            export EDITOR="nvr -l --remote-wait-silent"
          fi
        '';
    };
  };
}
