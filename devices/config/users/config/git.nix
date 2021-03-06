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
          glo = "pull origin";
          gpo = "push origin";
          gc = "clone";
        };
        extraConfig = {
          core.editor = "vim";
          pull.rebase = "false";
        };
      };
    };
  };
}
