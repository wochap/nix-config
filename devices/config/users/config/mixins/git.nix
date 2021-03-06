{ config, pkgs, ... }:

{
  config = {
    home-manager.users.gean = {
      # Generates ~/.gitconfig
      programs.git = {
        package = pkgs.gitAndTools.gitFull;
        enable = true;
        userName = "wochap";
        userEmail = "gean.marroquin@gmail.com";
        aliases = {
          co = "checkout";
          ci = "commit";
          st = "status";
        };
        extraConfig = {
          core.editor = "vim";
          pull.rebase = "false";
          init = {
            defaultBranch = "main";
          };
        };
      };
    };
  };
}
