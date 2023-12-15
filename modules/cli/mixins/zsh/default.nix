{ config, pkgs, lib, inputs, _customLib, ... }:

let
  cfg = config._custom.cli.zsh;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);
in {
  options._custom.cli.zsh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    users.users.${userName}.shell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableGlobalCompInit = false;
      promptInit = "";
      # enableLsColors = false;
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "zsh/.p10k.zsh".source = relativeSymlink ./.p10k.zsh;
        "zsh/nix-store/command-not-found.sh".source = "${hmConfig.programs.nix-index.package}/etc/profile.d/command-not-found.sh";
        "zsh/key-bindings-vi.zsh".source = ./key-bindings-vi.zsh;
        "fsh/catppuccin-mocha.ini".source =
          "${inputs.catppuccin-zsh-fsh}/themes/catppuccin-mocha.ini";
      };

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        envExtra = ''
          # make word movement commands to stop at every character except:
          # WORDCHARS="*?_-.[]~=/&;!#$%^(){}<>"
          export WORDCHARS="_*"
        '';
        initExtraFirst = ''
          # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
          # Initialization code that may require console input (password prompts, [y/n]
          # confirmations, etc.) must go above this block; everything else may go below.
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi

          # Install zinit
          ZINIT_HOME="''${XDG_DATA_HOME:-''${HOME}/.local/share}/zinit/zinit.git"
          [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
          [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
          source "''${ZINIT_HOME}/zinit.zsh"
        '';
        initExtra = ''
          source ${relativeSymlink ./config.zsh}
          source ${relativeSymlink ./functions.zsh}
          source ${relativeSymlink ./plugins.zsh}
        '';
        enableCompletion = false;
        enableAutosuggestions = false;
        # syntaxHighlighting.enable = false;
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
      programs.starship.enableZshIntegration = false; # enabled by default
      programs.zoxide.enableZshIntegration = false; # zinit takes care of this
      programs.navi.enableZshIntegration = false; # zinit takes care of this
      programs.nix-index.enableZshIntegration = false; # zinit takes care of this
      programs.fzf.enableZshIntegration = false; # zinit takes care of this
    };
  };
}
