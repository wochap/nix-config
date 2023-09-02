{ config, pkgs, ... }:

let userName = config._userName;
in {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        lazygit = prev.lazygit.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "jesseduffield";
            repo = "lazygit";
            rev = "e60936e964e0b978532745f319fc4600c00de7d7";
            sha256 = "sha256-fP12JfOyeXdQXUur2PToV29PIXc9bT3J/xJr75BOC0o=";
          };
        });
      })
    ];

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
        package = pkgs.unstable.lazygit;
        settings = {
          os = {
            open = "xdg-open {{filename}} >/dev/null";
            edit =
              "nvr -cc split --remote-wait +'set bufhidden=wipe' {{filename}}";
            # TODO: add editAtLine
            suspend = true;
          };
          gui = {
            showFileTree = false;
            scrollHeight = 10;
          };
          git.paging = {
            colorArg = "always";
            pager = "delta --paging=never";
          };
        };
      };

      # TODO: setup gh signature verification
      # Generates ~/.gitconfig
      programs.git = {
        package = pkgs.gitAndTools.gitFull;
        enable = true;

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

          user = {
            email = "gean.marroquin@gmail.com";
            name = "wochap";
            signingKey = "gean.marroquin@gmail.com";
          };
          commit = { gpgSign = true; };
        };
        includes = [
          # { path = ./dotfiles/gitconfig.dracula; }

          {
            condition = "gitdir:~/Projects/boc/**/.git";
            contents = {
              user = {
                email = "geanb@bandofcoders.com";
                name = "Gean";
                signingKey = "geanb@bandofcoders.com";
              };
              commit = { gpgSign = true; };
            };
          }
        ];

      };
    };
  };
}
