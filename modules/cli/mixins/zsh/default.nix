{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.cli.zsh;
  userName = config._userName;
in {
  options._custom.cli.zsh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    users.users.${userName}.shell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableGlobalCompInit = false;
      # enableLsColors = false;
      promptInit = "";
    };

    home-manager.users.${userName} = {
      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtraBeforeCompInit = ''
          source ${inputs.zsh-autocomplete}/zsh-autocomplete.plugin.zsh
          zstyle ':autocomplete:*' delay 0.1
        '';
        initExtra = ''
          source ${pkgs.oh-my-zsh}/plugins/aliases/aliases.plugin.zsh

          source ${./config.zsh}
          source ${./nnn.zsh}
          source ${./functions.zsh}
          source ${./key-bindings.zsh}
          source ${inputs.fuzzy-sys}/fuzzy-sys.plugin.zsh

          source ${inputs.catppuccin-zsh-syntax-highlighting}/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
          # Remove underline under paths (catppuccin_mocha-zsh-syntax-highlighting)
          (( ''${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
          ZSH_HIGHLIGHT_STYLES[path]='fg=#cdd6f4'
          ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#f38ba8'
          ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#cdd6f4'
          ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#f38ba8'
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        '';
        enableCompletion = false;
        # syntaxHighlighting.enable = false;
        enableAutosuggestions = true;
        # HACK: disable zsh viins mode
        # If one of the VISUAL or EDITOR environment variables contain the string 'vi' when the shell starts up then it will be viins
        defaultKeymap = "emacs";
        history = {
          ignoreDups = false;
          expireDuplicatesFirst = true;
          extended = true;
          ignoreSpace = true;
          save = 1000000000;
          size = 1000000000;
          # Shares current history file between all sessions as soon as shell closes
          share = true;
        };
        dirHashes = {
          nxc = "$HOME/nix-config";
          nxs = "/nix/store";
          dl = "$HOME/Downloads";
        };
      };

      programs.starship.enableZshIntegration = true;
      programs.zoxide.enableZshIntegration = true;
      programs.fzf.enableZshIntegration = true;
      programs.dircolors.enableZshIntegration = true;
    };
  };
}
