{ config, pkgs, lib, inputs, ... }:

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
          # setup https://github.com/catppuccin/fzf
          "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
          "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
          "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

          # mappings
          "--bind 'ctrl-d:preview-half-page-down"
          "--bind 'ctrl-u:preview-half-page-up'"
          "--bind 'ctrl-e:abort'"
          "--bind 'ctrl-y:accept'"
          "--bind 'ctrl-f:half-page-down'"
          "--bind 'ctrl-b:half-page-up'"
        ];
        # CTRL-T - Paste the selected file path(s) into the command line
        fileWidgetOptions =
          [ "--preview 'bat --style=numbers --color=always {}'" ];
        # CTRL-R - Paste the selected command from history into the command line
        historyWidgetOptions = [ ];
        # ALT-C - cd into the selected directory
        changeDirWidgetOptions = [ "--preview 'tree -C {} | head -100'" ];
      };
    };
  };
}
