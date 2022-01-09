{ config, pkgs, lib, inputs,  ... }:

let
  isDarwin = config._displayServer == "darwin";
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
  zshExtra = if (isDarwin) then "" else ''
    key=(
      Up "''${terminfo[kcuu1]}"
      Down "''${terminfo[kcud1]}"
    )

    # better up arrow history
    autoload -U up-line-or-beginning-search
    autoload -U down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey "$key[Up]" up-line-or-beginning-search # Up
    bindkey "$key[Down]" down-line-or-beginning-search # Down
  '';
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

          ${zshExtra}

          # source ${zsh-vim-mode}/zsh-vim-mode.plugin.zsh
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${dracula-zsh-syntax-highlighting}/zsh-syntax-highlighting.sh
          source ${inputs.ohmyzsh}/plugins/web-search/web-search.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/copydir/copydir.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/copyfile/copyfile.plugin.zsh

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
