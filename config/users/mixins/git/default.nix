{ config, pkgs, ... }:

let userName = config._userName;
in {
  config = {
    environment = {
      shellAliases = {
        gs = "git status";
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
      };
    };

    home-manager.users.${userName} = {
      home.packages = with pkgs; [ commitizen ];

      # TODO: setup gh signature verification
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
          color.ui = "auto";
          core.editor = "vim";
          pull.rebase = "false";
          init = { defaultBranch = "main"; };
        };
      };
    };
  };
}
