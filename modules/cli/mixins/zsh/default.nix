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
      home.sessionVariables = {
        # zsh-autocomplete: dont add key bindings
        # https://github.com/wochap/zsh-autocomplete#options
        AUTOCOMPLETE_INHIBIT_INIT = "1";

        # https://github.com/zsh-users/zsh-history-substring-search
        # change the behavior of history-substring-search-up
        HISTORY_SUBSTRING_SEARCH_PREFIXED = "1";

        # make word movement commands to stop at every character except:
        # WORDCHARS = "*?_-.[]~=/&;!#$%^(){}<>";
        WORDCHARS = "_*";

        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND = "bg=cyan,fg=black,bold";
        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND = "bg=red,fg=black,bold";
      };

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtraBeforeCompInit = ''
          # Install https://github.com/marlonrichert/zsh-autocomplete
          source ${inputs.zsh-autocomplete}/zsh-autocomplete.plugin.zsh

          # Increase zsh-autocomplete delay
          zstyle ':autocomplete:*' delay 0.1

          # Don't add spaces after accepting an option
          zstyle ':autocomplete:*' add-space ""
        '';
        initExtra = ''
          source ${inputs.fuzzy-sys}/fuzzy-sys.plugin.zsh
          source ${inputs.zsh-history-substring-search}/zsh-history-substring-search.zsh
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/aliases/aliases.plugin.zsh
          source ${inputs.zsh-autopair}/autopair.zsh
          autopair-init
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh

          source ${./config.zsh}
          source ${./nnn.zsh}
          source ${./functions.zsh}

          source ${inputs.catppuccin-zsh-syntax-highlighting}/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
          # Remove underline under paths (catppuccin_mocha-zsh-syntax-highlighting)
          (( ''${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
          ZSH_HIGHLIGHT_STYLES[path]='fg=#cdd6f4'
          ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#f38ba8'
          ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#cdd6f4'
          ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#f38ba8'
          source ${inputs.zsh-syntax-highlighting}/zsh-syntax-highlighting.zsh

          # HACK: zsh-syntax-highlighting mess up my key bindings
          source ${./key-bindings.zsh}
        '';
        enableCompletion = false;
        # syntaxHighlighting.enable = false;
        enableAutosuggestions = true;
        # HACK: disable zsh viins mode
        # If one of the VISUAL or EDITOR environment variables contain the string 'vi' when the shell starts up then it will be viins
        defaultKeymap = "emacs";
        history = {
          # TODO: add ignorePatterns
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
