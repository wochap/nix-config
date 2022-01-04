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
           ${builtins.readFile ./.zshrc.zsh}

          # source ${zsh-vim-mode}/zsh-vim-mode.plugin.zsh
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
          };
          package = {
            disabled = true;
          };
        };
      };
    };
  };
}
