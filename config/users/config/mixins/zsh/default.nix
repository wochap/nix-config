{ config, pkgs, lib,  ... }:

let
  userName = config._userName;
  dracula-zsh-syntax-highlighting = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "zsh-syntax-highlighting";
    rev = "47ba26d2d4912a1b8de066e589633ff1963c5621";
    sha256 = "1rhvbaz2v8kcggvh3flj6ri2jry4wdz6xx5br91i36f5alc2vk1i";
  };
  zsh-vim-mode = pkgs.fetchFromGitHub {
    owner = "softmoth";
    repo = "zsh-vim-mode";
    rev = "1f9953b7d6f2f0a8d2cb8e8977baa48278a31eab";
    sha256 = "sha256-a+6EWMRY1c1HQpNtJf5InCzU7/RphZjimLdXIXbO6cQ=";
  };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        zsh-syntax-highlighting
        exa
      ];
      pathsToLink = [
        "/share/zsh"
      ];
    };
    home-manager.users.${userName} = {
      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtra = ''
          key=(
            BackSpace  "''${terminfo[kbs]}"
            Home       "''${terminfo[khome]}"
            End        "''${terminfo[kend]}"
            Insert     "''${terminfo[kich1]}"
            Delete     "''${terminfo[kdch1]}"
            Up         "''${terminfo[kcuu1]}"
            Down       "''${terminfo[kcud1]}"
            Left       "''${terminfo[kcub1]}"
            Right      "''${terminfo[kcuf1]}"
            PageUp     "''${terminfo[kpp]}"
            PageDown   "''${terminfo[knp]}"
          )

          # ENABLE ZSH COMPLETION SYSTEM (OMZSH USED TO DO IT FOR US)
          zmodload -i zsh/complist
          autoload -U bashcompinit
          bashcompinit

          function killport {
            kill $(lsof -t -i:"$1")
          }

          # Allow changing directories without `cd`.
          setopt AUTOCD

          # Allow shift-tab in ZSH suggestions
          bindkey '^[[Z' reverse-menu-complete

          # case-insensitive completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

          # highlight selection
          zstyle ':completion:*' menu select

          # better up arrow history
          autoload -U up-line-or-beginning-search
          autoload -U down-line-or-beginning-search
          zle -N up-line-or-beginning-search
          zle -N down-line-or-beginning-search
          bindkey "$key[Up]" up-line-or-beginning-search # Up
          bindkey "$key[Down]" down-line-or-beginning-search # Down

          ### Fix slowness of pastes with zsh-syntax-highlighting.zsh
          ### https://github.com/zsh-users/zsh-autosuggestions/issues/238
          pasteinit() {
            OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
            zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
          }

          pastefinish() {
            zle -N self-insert $OLD_SELF_INSERT
          }
          zstyle :bracketed-paste-magic paste-init pasteinit
          zstyle :bracketed-paste-magic paste-finish pastefinish
          ### Fix slowness of pastes

          # Clear right promt
          RPROMPT=""

          # Completion for kitty
          kitty + complete setup zsh | source /dev/stdin

          # Setup lorri/direnv
          export DIRENV_LOG_FORMAT=
          eval "$(direnv hook zsh)"

          # Remove superfluous blanks being added to history.
          setopt HIST_REDUCE_BLANKS

          # Don't display duplicates when searching the history with Ctrl+R.
          setopt HIST_FIND_NO_DUPS

          # Don't enter _any_ repeating commands into the history.
          setopt HIST_IGNORE_ALL_DUPS
          # Ignore duplicates when writing history file.
          setopt HIST_SAVE_NO_DUPS

          # Sessions append to the history list in the order they exit.
          setopt APPEND_HISTORY

          source ${zsh-vim-mode}/zsh-vim-mode.plugin.zsh
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${dracula-zsh-syntax-highlighting}/zsh-syntax-highlighting.sh

          ${builtins.readFile ./awesome.zsh}
        '';
        enableCompletion = true;
        enableAutosuggestions = true;
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
        oh-my-zsh = {
          enable = false;
        };
        shellAliases = lib.mkMerge [
          config.environment.shellAliases
          {
            ns = "nix-shell --run zsh";

            # Setup exa
            ls = lib.mkForce "exa --icons --group-directories-first --across";
            la = lib.mkForce "exa --icons --group-directories-first --all --long";

            # Setup ptSh
            pwdd = "ptpwd";
            mkdir = "ptmkdir";
            touch = "pttouch";
            cp = "ptcp";
            rm = "ptrm";
          }
        ];
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          add_newline = false;
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };
          nix_shell = {
            disabled = true;
            symbol = "❄️ lorri ";
            format = "via [$symbol]($style) ";
          };
          package = {
            disabled = true;
          };
        };
      };
    };
  };
}
