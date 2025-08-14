{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.kitty;
  inherit (config._custom.globals)
    themeColorsLight themeColorsDark preferDark configDirectory;
  inherit (lib._custom) relativeSymlink unwrapHex;

  kitty-final = pkgs.nixpkgs-unstable.kitty;
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
  mkKittyTheme = themeColors: ''
    include ${inputs.catppuccin-kitty}/themes/${themeColors.flavour}.conf

    cursor ${themeColors.green}
    cursor_text_color ${themeColors.base}
    active_border_color ${themeColors.primary}
    inactive_border_color ${themeColors.border}
    tab_bar_background ${themeColors.base}
    inactive_tab_background ${themeColors.base}
    # color0
    inactive_tab_foreground ${themeColors.surface1}
    active_tab_background ${themeColors.lavender}
    active_tab_foreground ${themeColors.base}
  '';
  catppuccin-kitty-light-theme = mkKittyTheme themeColorsLight;
  catppuccin-kitty-dark-theme = mkKittyTheme themeColorsDark;
in {
  options._custom.programs.kitty.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # env variable to be used within neovim config
    environment.sessionVariables.GLOBAL_KITTY_FOLDER_PATH = "${kitty-final}";

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
      programs.zsh.initContent = lib.mkOrder 1000 shellIntegrationInit.zsh;

      xdg.configFile = {
        "kitty/diff.conf".text = let
          rawContent = builtins.readFile
            "${inputs.catppuccin-kitty}/themes/diff-${themeColorsDark.flavour}.conf";
          lines = lib.strings.splitString "\n" rawContent;
          processedLines = map (line:
            let match = builtins.match "^([a-zA-Z0-9_-]+)(.*)" line;
            in if match == null then
              line
            else
              "dark_${builtins.elemAt match 0}${builtins.elemAt match 1}")
            lines;
          darkDiff = lib.strings.concatStringsSep "\n" processedLines;
        in ''
          ${builtins.readFile
          "${inputs.catppuccin-kitty}/themes/diff-${themeColorsLight.flavour}.conf"}
          ${darkDiff}
          ${builtins.readFile ./dotfiles/kitty-diff.conf}
        '';
        "kitty/light-theme.auto.conf".text = catppuccin-kitty-light-theme;
        "kitty/dark-theme.auto.conf".text = catppuccin-kitty-dark-theme;
        "kitty/no-preference-theme.auto.conf".text = if preferDark then
          catppuccin-kitty-dark-theme
        else
          catppuccin-kitty-light-theme;
        "kitty/kitty.conf".text = ''
          shell ${pkgs.zsh}/bin/zsh
          include ${relativeSymlink configDirectory ./dotfiles/kitty.conf}

          # TODO: move into *-theme.auto.conf
          # currently we can't because it doesn't work there
          # color0 is surface1
          tab_title_template "{fmt.bg.default}{fmt.fg.color0}  {sup.index} 󰓩 {title[:30]}{bell_symbol}{activity_symbol}  {fmt.fg.default}"
          active_tab_title_template "{fmt.bg.default}{fmt.fg._${
            unwrapHex themeColorsDark.lavender
          }}{fmt.bg._${
            unwrapHex themeColorsDark.lavender
          }}{fmt.fg.color0} {sup.index} 󰓩 {title[:30]}{bell_symbol}{activity_symbol} {fmt.bg.default}{fmt.fg._${
            unwrapHex themeColorsDark.lavender
          }}{fmt.bg.default}{fmt.fg.default}"
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

        # required by smart-splits.nvim
        "kitty/neighboring_window.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/neighboring_window.py";
          executable = true;
        };
        "kitty/relative_resize.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/relative_resize.py";
          executable = true;
        };

        # required by kitty-scrollback.nvim
        "kitty/kitty-scrollback-nvim" = {
          source = inputs.kitty-scrollback-nvim;
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
