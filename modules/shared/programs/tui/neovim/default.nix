{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.programs.neovim;
  inherit (config._custom.globals) userName configDirectory;
  hmConfig = config.home-manager.users.${userName};
  clear-nvim-state = pkgs.writeScriptBin "clear-nvim-state"
    # zsh
    ''
      #!/usr/bin/env bash

      ${pkgs.coreutils}/bin/rm -f ${hmConfig.xdg.stateHome}/nvim/conform.log
      ${pkgs.coreutils}/bin/rm -f ${hmConfig.xdg.stateHome}/nvim/lsp.log
      ${pkgs.coreutils}/bin/rm -f ${hmConfig.xdg.stateHome}/nvim/nvim-tree.log
    '';

  # final-nvim = lib.mkDefault inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  final-nvim = pkgs.prevstable-neovim.neovim-unwrapped.overrideAttrs
    (oldAttrs: rec {
      patches = (oldAttrs.patches or [ ])
        ++ [
          # apply https://github.com/neovim/neovim/pull/35195
          # source: https://github.com/nvim-neotest/neotest/issues/527
          # source: https://github.com/neovim/neovim/issues/35071
          ./neovim-mark-nvim_create_autocmd-as-api-fast.patch
        ];
    }); # 0.11.1
in {
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    _custom.programs.neovim = {
      setBuildEnv = true;
      withBuildTools = true;
      package = lib.mkDefault final-nvim;
    };

    environment = {
      systemPackages = with pkgs; [
        neovide # gui

        marksman # required by nvim-lspconfig
        neovim-remote # required by lazygit
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

      programs.git = {
        extraConfig.core.editor = "nvim";
        ignores = [ ".nolazy.lua" ".lazy.lua" ];
      };

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
        nvl = ''LITE=true run-without-kpadding nvim "$@"'';
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

      systemd.user.services.clear-nvim-state = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          ExecStart = "${clear-nvim-state}/bin/clear-nvim-state";
        };
      };
    };
  };
}
