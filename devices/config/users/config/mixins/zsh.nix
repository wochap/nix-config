{ config, pkgs, lib,  ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        zsh-fast-syntax-highlighting
        starship
      ];
      pathsToLink = [
        "/share/zsh"
      ];
    };
    home-manager.users.gean = {
      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        initExtra = ''
          # Setup starship theme
          eval "$(starship init zsh)"

          function desktop4() {
            /etc/bspwm_desktop_4.sh
          }

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

          # Auto run nix-shell
          export DIRENV_LOG_FORMAT=
          eval "$(direnv hook zsh)"

          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
        '';
        enableCompletion = true;
        enableAutosuggestions = true;
        oh-my-zsh = {
          enable = true;
          plugins = [];
        };
        shellAliases = lib.mkMerge [
          config.environment.shellAliases
          {
            ns = "nix-shell --run zsh";
            f = "nnn";

            # Setup ptSh
            ls = lib.mkForce "ptls";
            pwd = "ptpwd";
            mkdir = "ptmkdir";
            touch = "pttouch";
            cp = "ptcp";
            rm = "ptrm";
          }
        ];
      };
    };
  };
}
