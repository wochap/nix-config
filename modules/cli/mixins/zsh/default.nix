{ config, pkgs, lib, inputs, _customLib, ... }:

let
  cfg = config._custom.cli.zsh;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);

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

        # completions
        unstable.zsh-completions
      ];

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        envExtra = ''
          ## misc

          # make word movement commands to stop at every character except:
          # WORDCHARS="*?_-.[]~=/&;!#$%^(){}<>"
          export WORDCHARS="_*"
        '';
        initExtraBeforeCompInit = "";
        completionInit = ''
          ## zsh-autocomplete

          # Show dotfiles in complete menu
          setopt GLOB_DOTS

          # Disable zsh-autocomplete key bindings
          zstyle ':autocomplete:key-bindings' enabled no

          # Increase zsh-autocomplete delay
          zstyle ':autocomplete:*' delay 0.1

          # Don't add spaces after accepting an option
          zstyle ':autocomplete:*' add-space ""

          source ${inputs.zsh-autocomplete}/zsh-autocomplete.plugin.zsh
        '';
        initExtra = ''
          source ${relativeSymlink ./config.zsh}
          source ${relativeSymlink ./functions.zsh}

          function load_key_bindings() {
            source ${relativeSymlink ./key-bindings-vi.zsh}
          }

          ## zsh-autosuggestions

          export ZSH_AUTOSUGGEST_MANUAL_REBIND=true
          export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

          ## zsh-fsh

          # remove background from pasted text
          # source: https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/25
          # docs: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
          zle_highlight=('paste:fg=white,bold')

          # HACK: set catppuccin-mocha theme for zsh-fast-syntax-highlighting
          FAST_WORK_DIR="${fshTheme}"
          source ${fshPlugin.src}/${fshPlugin.file}

          ## zsh-vi-mode

          function zvm_config() {
            ZVM_VI_INSERT_ESCAPE_BINDKEY=^X
            ZVM_VI_HIGHLIGHT_BACKGROUND=#45475A
            ZVM_VI_HIGHLIGHT_FOREGROUND=#cdd6f4
            ZVM_VI_SURROUND_BINDKEY=s-prefix
            ZVM_ESCAPE_KEYTIMEOUT=0
            ZVM_LINE_INIT_MODE=$ZVM_MODE_LAST
            ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
            ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
          }

          typeset -g VI_MODE="%B%F{#1E1E2E}%K{#a6e3a1} INSERT %k%f%b"
          RPROMPT=$VI_MODE
          function zvm_after_select_vi_mode() {
            case $ZVM_MODE in
              $ZVM_MODE_NORMAL)
                VI_MODE="%B%F{#1E1E2E}%K{#b4befe} NORMAL %k%f%b"
              ;;
              $ZVM_MODE_INSERT)
                VI_MODE="%B%F{#1E1E2E}%K{#a6e3a1} INSERT %k%f%b"
              ;;
              $ZVM_MODE_VISUAL)
                VI_MODE="%B%F{#1E1E2E}%K{#f2cdcd} VISUAL %k%f%b"
              ;;
              $ZVM_MODE_VISUAL_LINE)
                VI_MODE="%B%F{#1E1E2E}%K{#f2cdcd} V-LINE %k%f%b"
              ;;
              $ZVM_MODE_REPLACE)
                VI_MODE="%B%F{#1E1E2E}%K{#eba0ac} REPLACE %k%f%b"
              ;;
            esac
            RPROMPT=$VI_MODE
          }

          function zvm_after_init() {
            load_key_bindings

            # HACK: fix race condition where zsh-vi-mode overwrites fzf key-binding
            bindkey -M viins '^R' fzf-history-widget
          }

          source ${inputs.zsh-vi-mode}/zsh-vi-mode.plugin.zsh

          ## zsh-history-substring-search

          # https://github.com/zsh-users/zsh-history-substring-search
          # change the behavior of history-substring-search-up
          export HISTORY_SUBSTRING_SEARCH_PREFIXED="1"

          export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=cyan,fg=16,bold"
          export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="bg=red,fg=16,bold"

          source ${inputs.zsh-history-substring-search}/zsh-history-substring-search.zsh

          ## zsh-abbr

          export ABBR_DEFAULT_BINDINGS=0

          source ${pkgs.unstable.zsh-abbr}/share/zsh-abbr/zsh-abbr.zsh

          bindkey -M viins " " abbr-expand-and-space

          if [[ ! -e "$ABBR_USER_ABBREVIATIONS_FILE" || ! -s "$ABBR_USER_ABBREVIATIONS_FILE" ]]; then
            abbr import-aliases --quiet
            abbr erase --quiet nv
            abbr erase --quiet nvim
            abbr erase --quiet ls
            abbr erase --quiet la
            abbr erase --quiet lt
            abbr erase --quiet ll
            abbr erase --quiet lla
            abbr erase --quiet z
          fi

          ## snippets

          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/aliases/aliases.plugin.zsh
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh
          source ${inputs.fuzzy-sys}/fuzzy-sys.plugin.zsh
        '';
        enableCompletion = true;
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
          # TODO: add ignorePatterns
        };
        dirHashes = {
          nxc = "$HOME/nix-config";
          nxs = "/nix/store";
          dl = "$HOME/Downloads";
        };
      };

      # programs.carapace.enableZshIntegration = true;
      # programs.thefuck.enableZshIntegration = true;
      programs.dircolors.enableZshIntegration = true;
      programs.starship.enableZshIntegration = true;
      programs.zoxide.enableZshIntegration = true;
      programs.navi.enableZshIntegration = true;
      programs.nix-index.enableZshIntegration = true;
      programs.fzf.enableZshIntegration = true;
    };
  };
}
