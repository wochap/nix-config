{ config, pkgs, ... }:

let
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
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
