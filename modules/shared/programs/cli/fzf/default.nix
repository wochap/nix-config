{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.fzf;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;

  get-catppuccin-fzf-args = themeStr:
    let
      lines = lib.strings.splitString "\n" themeStr;
      tailLines = lib.lists.tail lines;
      processedLines = lib.lists.map (line:
        let cleanedLine = builtins.replaceStrings [ "\\" ''"'' ] [ "" "" ] line;
        in lib.strings.trim cleanedLine) tailLines;
    in processedLines;
  catppuccin-fzf-light-theme-args = get-catppuccin-fzf-args (lib.fileContents
    "${inputs.catppuccin-fzf}/themes/catppuccin-fzf-${themeColorsLight.flavour}.sh");
  catppuccin-fzf-dark-theme-args = get-catppuccin-fzf-args (lib.fileContents
    "${inputs.catppuccin-fzf}/themes/catppuccin-fzf-${themeColorsDark.flavour}.sh");
in {
  options._custom.programs.fzf.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.programs.rod.config = {
      cmds.fzf.light = {
        pre_args = [ "--color=light" ] ++ catppuccin-fzf-light-theme-args;
        pos_args = [ ];
      };
      cmds.fzf.dark = {
        pre_args = [ "--color=dark" ] ++ catppuccin-fzf-dark-theme-args;
        pos_args = [ ];
      };
    };

    _custom.hm = {
      programs.zsh.shellAliases.fzf = ''rod run fzf -- "$@"'';

      programs.fzf = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = config._custom.programs.zsh.enable;
        defaultOptions = [
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
