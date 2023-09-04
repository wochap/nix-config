{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
in {
  config = {
    environment.pathsToLink = [ "/share/zsh" ];

    home-manager.users.${userName} = {
      # Make sure we create a cache directory since some plugins expect it to exist
      # See: https://github.com/nix-community/home-manager/issues/761
      home.file."${hmConfig.xdg.cacheHome}/oh-my-zsh/.keep".text = "";

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtra = ''
          # oh-my-zsh
          export ZSH="${inputs.ohmyzsh}"
          ${builtins.readFile ./ohmyzsh.zsh}
          source ${inputs.ohmyzsh}/lib/key-bindings.zsh
          source ${inputs.ohmyzsh}/lib/completion.zsh
          source ${inputs.ohmyzsh}/lib/clipboard.zsh
          source ${inputs.ohmyzsh}/plugins/copyfile/copyfile.plugin.zsh
          source ${inputs.ohmyzsh}/plugins/dirhistory/dirhistory.plugin.zsh

          if [[ $options[zle] = on ]]; then
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          fi

          ${builtins.readFile ./config.zsh}
          ${builtins.readFile ./nnn.zsh}
          ${builtins.readFile ./functions.zsh}

          # load function completions in /share/zsh folder
          zmodload zsh/complist
          # autoload -Uz bashcompinit compinit
          # bashcompinit
          autoload -U compinit && compinit

          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${inputs.catppuccin-zsh-syntax-highlighting}/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
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
        prezto = { enable = false; };
        oh-my-zsh = { enable = false; };
        dirHashes = {
          nxc = "$HOME/nix-config";
          nxs = "/nix/store";
          dl = "$HOME/Downloads";
        };
      };

      programs.starship.enableZshIntegration = true;

      # Enabled on programs.zsh.initExtra
      # programs.fzf.enableZshIntegration = true;
    };
  };
}
