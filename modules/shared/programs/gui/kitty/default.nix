{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.kitty;
  inherit (config._custom.globals) themeColors configDirectory;
  inherit (lib._custom) relativeSymlink unwrapHex;

  kitty-final = pkgs.kitty;
  shellIntegrationInit = {
    bash = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
      fi
    '';
    zsh = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      fi
    '';
  };
in {
  options._custom.programs.kitty.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables.PYTHONPATH = [ "${kitty-final}/lib/kitty" ];

    _custom.hm = {
      home = {
        packages = [ kitty-final ];

        sessionVariables = {
          # TODO: test on darwin ⬇
          TERMINAL = "kitty";
        };

        shellAliases = {
          kdiff = "kitty +kitten diff";
          icat = "kitty +kitten icat";
          # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
          sshk = "kitty +kitten ssh";
        };
      };

      # manually add kitty shell integration
      programs.bash.initExtra = shellIntegrationInit.bash;
      programs.zsh.initExtra = shellIntegrationInit.zsh;

      xdg.configFile = {
        "kitty/diff.conf".text = ''
          include ${inputs.catppuccin-kitty}/themes/diff-late.conf
          ${builtins.readFile ./dotfiles/kitty-diff.conf}
        '';
        "kitty/kitty.conf".text = ''
          include ${inputs.catppuccin-kitty}/themes/${themeColors.flavor}.conf
          cursor ${themeColors.green}
          cursor_text_color ${themeColors.base}
          active_border_color ${themeColors.primary}
          inactive_border_color ${themeColors.border}
          tab_title_template "{fmt.bg.default}{fmt.fg._${
            unwrapHex themeColors.surface1
          }}  {sup.index} 󰓩 {title[:30]}{bell_symbol}{activity_symbol}  {fmt.fg.default}"
          active_tab_title_template "{fmt.bg.default}{fmt.fg._${
            unwrapHex themeColors.lavender
          }}{fmt.bg._${unwrapHex themeColors.lavender}}{fmt.fg._${
            unwrapHex themeColors.surface1
          }} {sup.index} 󰓩 {title[:30]}{bell_symbol}{activity_symbol} {fmt.bg.default}{fmt.fg._${
            unwrapHex themeColors.lavender
          }}{fmt.bg.default}{fmt.fg.default}"
          tab_bar_background ${themeColors.base}
          active_tab_foreground ${themeColors.base}
          inactive_tab_background ${themeColors.base}
          inactive_tab_foreground ${themeColors.surface1}

          include ${relativeSymlink configDirectory ./dotfiles/kitty.conf}
        '';
        "kitty/open-actions.conf".source = ./dotfiles/open-actions.conf;
        "kitty/mime.types".source = ./dotfiles/mime.types;

        "kitty/tab_bar.py" = {
          source = ./dotfiles/tab_bar.py;
          executable = true;
        };

        # scripts
        "kitty/scripts" = {
          recursive = true;
          source = ./scripts;
        };

        # kittens
        "kitty/replace_alt_shift_backspace.py" = {
          source = ./dotfiles/replace_alt_shift_backspace.py;
          executable = true;
        };
        "kitty/custom_pass_keys.py" = {
          source = ./dotfiles/custom_pass_keys.py;
          executable = true;
        };
        "kitty/neighboring_window.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/neighboring_window.py";
          executable = true;
        };
        "kitty/relative_resize.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/relative_resize.py";
          executable = true;
        };
        "kitty/kitty_scrollback_nvim.py" = {
          source =
            "${inputs.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py";
          executable = true;
        };
        "kitty/smart_scroll.py" = {
          source = "${inputs.kitty-smart-scroll}/smart_scroll.py";
          executable = true;
        };
        "kitty/smart_tab.py" = {
          source = "${inputs.kitty-smart-tab}/smart_tab.py";
          executable = true;
        };
      };

    };
  };
}
