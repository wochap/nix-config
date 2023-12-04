{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.fzf;
  userName = config._userName;
in {
  options._custom.cli.fzf = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      programs.fzf = {
        enable = true;
        package = pkgs.unstable.fzf;
        enableBashIntegration = true;
        defaultOptions = [
          # theme
          # source: https://github.com/catppuccin/fzf
          "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
          "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
          "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

          "--no-height"
          "--tabstop=2"
          "--cycle"
          "--layout=default"
          "--no-separator"
          "--scroll-off=4"

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
