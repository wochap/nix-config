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

      programs.lazygit = {
        enable = true;
        settings = {
          gui = { showFileTree = false; };
          git.paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never";
            # useConfig = true;
          };
        };
      };

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

        delta = {
          enable = true;
          options = {
            features = "side-by-side line-numbers decorations";
            syntax-theme = "Dracula";
            plus-style = ''syntax "#003800"'';
            minus-style = ''syntax "#3f0001"'';
            navigate = true;
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
              hunk-header-decoration-style = "cyan box ul";
            };
            line-numbers = {
              line-numbers-left-style = "cyan";
              line-numbers-right-style = "cyan";
              line-numbers-minus-style = "124";
              line-numbers-plus-style = "28";
            };
          };
        };

        extraConfig = {
          diff = { colorMoved = "default"; };
          color.ui = "auto";
          pull.rebase = "false";
          init = { defaultBranch = "main"; };
          merge = { conflictstyle = "diff3"; };
        };
        # includes = [{ path = ./dotfiles/gitconfig.dracula; }];
      };
    };
  };
}
