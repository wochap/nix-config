{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.cli.zsh;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};

  fshPlugin = {
    name = "zsh-fast-syntax-highlighting";
    src = pkgs.zsh-fast-syntax-highlighting;
    file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
  };
  fshTheme = pkgs.stdenvNoCC.mkDerivation {
    name = "fsh-theme";
    nativeBuildInputs = [ pkgs.zsh ];
    buildCommand = ''
      zsh << EOF
        source "${fshPlugin.src}/${fshPlugin.file}"
        FAST_WORK_DIR="$out"
        mkdir -p "$out"
        fast-theme "${inputs.catppuccin-zsh-fsh}/themes/catppuccin-mocha.ini"
      EOF
    '';
  };
in {
  options._custom.cli.zsh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        zsh-abbr = prev.zsh-abbr.overrideAttrs (oldAttrs: rec {
          version = "5.2.0";

          src = prev.fetchFromGitHub {
            owner = "olets";
            repo = "zsh-abbr";
            rev = "v${version}";
            hash = "sha256-MvxJkEbJKMmYRku/RF6ayOb7u7NI4HZehO8ty64jEnE=";
          };

          installPhase = ''
            mkdir -p $out/share/zsh-abbr
            cp zsh-abbr.zsh zsh-abbr.plugin.zsh $out/share/zsh-abbr
            install -D completions/_abbr $out/share/zsh/site-functions/_abbr
            install -D man/man1/abbr.1 $out/share/man/man1/abbr.1
          '';
        });
      })
    ];

    users.users.${userName}.shell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableGlobalCompInit = false;
      promptInit = "";
      # enableLsColors = false;
    };

    home-manager.users.${userName} = {
      home.packages = with pkgs; [
        # completions and manpage install
        unstable.zsh-abbr

        # more completions
        unstable.zsh-completions
      ];

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        envExtra = ''
          # https://github.com/zsh-users/zsh-history-substring-search
          # change the behavior of history-substring-search-up
          export HISTORY_SUBSTRING_SEARCH_PREFIXED="1"

          export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=cyan,fg=16,bold"
          export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="bg=red,fg=16,bold"

          # make word movement commands to stop at every character except:
          # WORDCHARS="*?_-.[]~=/&;!#$%^(){}<>"
          export WORDCHARS="_*"

          # HACK: set catppuccin-mocha theme for zsh-fast-syntax-highlighting
          FAST_WORK_DIR="${fshTheme}"
        '';
        initExtraBeforeCompInit = ''
          # Show dotfiles in zsh-autocomplete
          # _comp_options+=(globdots)
          setopt GLOB_DOTS

          # Disable zsh-autocomplete key bindings
          zstyle ':autocomplete:key-bindings' enabled no

          # Increase zsh-autocomplete delay
          zstyle ':autocomplete:*' delay 0.1

          # Don't add spaces after accepting an option
          zstyle ':autocomplete:*' add-space ""

          # Install https://github.com/marlonrichert/zsh-autocomplete
          source ${inputs.zsh-autocomplete}/zsh-autocomplete.plugin.zsh

          # zsh-autosuggestions options
          export ZSH_AUTOSUGGEST_MANUAL_REBIND=true
          export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

          function zvm_config() {
            ZVM_VI_INSERT_ESCAPE_BINDKEY=^X
            ZVM_VI_HIGHLIGHT_BACKGROUND=#45475A
            ZVM_VI_HIGHLIGHT_FOREGROUND=#cdd6f4
            ZVM_VI_SURROUND_BINDKEY=s-prefix
            ZVM_ESCAPE_KEYTIMEOUT=0
            ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
            ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
            ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
          }
        '';
        initExtra = ''
          source ${inputs.fuzzy-sys}/fuzzy-sys.plugin.zsh
          source ${inputs.zsh-history-substring-search}/zsh-history-substring-search.zsh
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/aliases/aliases.plugin.zsh
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh
          source ${pkgs.unstable.zsh-abbr}/share/zsh-abbr/zsh-abbr.zsh

          source ${./config.zsh}
          source ${./nnn.zsh}
          source ${./functions.zsh}
          function zvm_after_init() {
            if [[ $options[zle] = on ]]; then
              . ${hmConfig.programs.fzf.package}/share/fzf/completion.zsh
              . ${hmConfig.programs.fzf.package}/share/fzf/key-bindings.zsh
            fi
            source ${./key-bindings-vi.zsh}
          }
          # source ${./key-bindings-emacs.zsh}

          if [[ ! -e "$ABBR_USER_ABBREVIATIONS_FILE" || ! -s "$ABBR_USER_ABBREVIATIONS_FILE" ]]; then
            abbr import-aliases --quiet
            abbr erase --quiet nv
            abbr erase --quiet nvim
            abbr erase --quiet ls
            abbr erase --quiet la
            abbr erase --quiet lt
            abbr erase --quiet ll
            abbr erase --quiet lla
          fi
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
        plugins = [
          fshPlugin
          {
            name = "zsh-vi-mode";
            src = inputs.zsh-vi-mode;
            file = "zsh-vi-mode.plugin.zsh";
          }
        ];
      };

      # programs.carapace.enableZshIntegration = true;
      # programs.thefuck.enableZshIntegration = true;
      programs.starship.enableZshIntegration = true;
      programs.zoxide.enableZshIntegration = true;
      programs.fzf.enableZshIntegration = lib.mkForce false;
      programs.dircolors.enableZshIntegration = true;
      programs.navi.enableZshIntegration = true;
      programs.nix-index.enableZshIntegration = true;
    };
  };
}
