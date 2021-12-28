{ config, pkgs, lib,  ... }:

let
  userName = config._userName;
  dracula-zsh-syntax-highlighting = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "zsh-syntax-highlighting";
    rev = "47ba26d2d4912a1b8de066e589633ff1963c5621";
    sha256 = "1rhvbaz2v8kcggvh3flj6ri2jry4wdz6xx5br91i36f5alc2vk1i";
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
          function killport {
            kill $(lsof -t -i:"$1")
          }

          # case-insensitive completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

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

          # ZSH settings
          unsetopt SHARE_HISTORY
          unsetopt INC_APPEND_HISTORY
          setopt INC_APPEND_HISTORY_TIME
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_FIND_NO_DUPS

          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${dracula-zsh-syntax-highlighting}/zsh-syntax-highlighting.sh
        '';
        enableCompletion = true;
        enableAutosuggestions = true;
        history = {
          extended = true;
          ignoreSpace = true;
          save = 1000000000;
          size = 1000000000;
          share = false;
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
