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
