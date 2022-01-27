{ config, pkgs, lib, inputs,  ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
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
          export ZSH="${inputs.ohmyzsh}"
          ${builtins.readFile ./ohmyzsh.zsh}
          ${builtins.readFile ./zshrc.zsh}

          source ${inputs.ohmyzsh}/lib/key-bindings.zsh
          source ${inputs.ohmyzsh}/lib/completion.zsh
          source ${inputs.ohmyzsh}/lib/clipboard.zsh
          source ${inputs.ohmyzsh}/plugins/web-search/web-search.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/copydir/copydir.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/copyfile/copyfile.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/dirhistory/dirhistory.plugin.zsh

          ${builtins.readFile ./awesome.zsh}

          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${inputs.dracula-zsh-syntax-highlighting}/zsh-syntax-highlighting.sh
        '';
        enableCompletion = false;
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
        prezto = {
          enable = false;
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
