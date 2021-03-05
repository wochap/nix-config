{ config, pkgs, lib,  ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      zsh-syntax-highlighting
    ];
    home-manager.users.gean = {
      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtra = ''
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

          RPROMPT=""

          # Auto run nix-shell
          eval "$(direnv hook zsh)"

          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        '';
        enableCompletion = true;
        enableAutosuggestions = true;
        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [];
        };
        shellAliases = lib.mkMerge [
          config.environment.shellAliases
          {
            ns = "nix-shell --run zsh";
          }
        ];
      };
    };
  };
}
