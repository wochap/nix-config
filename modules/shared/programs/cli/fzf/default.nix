{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.fzf;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  toListOfArgs = str: builtins.filter (line: line != "") (lib.splitString "\n" str);
  catppuccin-fzf-light-theme-args = toListOfArgs (
    lib.fileContents "${inputs.catppuccin-fzf}/themes/catppuccin-fzf-${themeColorsLight.flavour}.rc"
  );
  catppuccin-fzf-dark-theme-args = toListOfArgs (
    lib.fileContents "${inputs.catppuccin-fzf}/themes/catppuccin-fzf-${themeColorsDark.flavour}.rc"
  );
  fzf-default-args = [
    "--no-height"
    "--tabstop '2'"
    "--cycle"
    "--layout 'default'"
    "--no-separator"
    "--scroll-off '4'"
    "--prompt '❯ '"
    "--marker '❯'"
    "--pointer '❯'"
    "--scrollbar '🮉'"
    "--ellipsis '…'"

    # mappings
    "--bind 'ctrl-d:preview-half-page-down'"
    "--bind 'ctrl-u:preview-half-page-up'"
    "--bind 'ctrl-e:abort'"
    "--bind 'ctrl-y:accept'"
    "--bind 'ctrl-f:half-page-down'"
    "--bind 'ctrl-b:half-page-up'"
    "--bind '?:toggle-preview'"
  ];
in
{
  options._custom.programs.fzf = {
    enable = lib.mkEnableOption { };
    defaultOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        fzf-default-args
        ++ (if preferDark then catppuccin-fzf-dark-theme-args else catppuccin-fzf-light-theme-args);
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.sessionVariables.FZF_DEFAULT_OPTS = toString cfg.defaultOptions;

      programs.zsh.initContent = lib.mkOrder 1000 ''
        _apply_fzf_theme() {
          if [[ "$1" == "dark" ]]; then
              export FZF_DEFAULT_OPTS="${toString (fzf-default-args ++ catppuccin-fzf-dark-theme-args)}"
          else
              export FZF_DEFAULT_OPTS="${toString (fzf-default-args ++ catppuccin-fzf-light-theme-args)}"
          fi
        }
        add-theme-hook _apply_fzf_theme
        _apply_fzf_theme $CURRENT_SCHEME
      '';

      programs.fzf = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = config._custom.programs.zsh.enable;
        # CTRL-T - Paste the selected file path(s) into the command line
        fileWidgetOptions = [
          "--preview '(bat --style=numbers --color=always {} || lsd -l -A --ignore-glob=.git --tree --depth=2 --color=always --blocks=size,name {}) 2> /dev/null | head -200'"
          "--preview-window 'right:border-left:50%:<40(right:border-left:50%:hidden)'"
        ];
        # CTRL-R - Paste the selected command from history into the command line
        historyWidgetOptions = [
          "--preview 'echo {} | sed \\\"s/^ *\\([0-9|*]\\+\\) *//\\\" | bat --plain --language=sh --color=always'"
          "--preview-window 'down:border-top:4:<4(down:border-top:4:hidden)'"
        ];
        # ALT-C - cd into the selected directory
        changeDirWidgetOptions = [
          "--preview 'lsd -l -A --ignore-glob=.git --tree --depth=2 --color=always --blocks=size,name {} | head -200'"
          "--preview-window 'right:border-left:50%:<40(right:border-left:50%:hidden)'"
        ];
      };
    };
  };
}
